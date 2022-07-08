-- hs.pom_timer
--
-- A utility for menu bar timers and pomodoro timers, both of which can be
-- paused, unpaused, added to, and subtracted from. Built in combination with
-- Alfred: https://www.alfredapp.com 

pom_timer = {}

local options = {
    current_timer = nil, -- Hammerspoon timer instance
    menu_bar_app = nil, -- Hammerspoon menu bar instance
    initial_min = 0, -- Minutes set for the current timer
    sec_remaining = 0, -- Seconds left until the current timer is done
    timer_message = '', -- Optional message to show to the side of the timer
    is_work_session = false, -- If the current timer is a pomodoro work session
    is_pom_timer = false, -- If the current timer is a pomodoro timer
    completed_pom_count = 0 -- Total number of pomodoros completed
}

-- Default pomodoro timings
-- Work session: 25 minutes
-- Small break session: 5 minutes
-- Large break session: 15 minutes
local WORK_MIN = 25
local SMALL_BREAK_MIN = 5
local LARGE_BREAK_MIN = 15

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_update_display()
    menu_bar_text = ''
    time_min = math.floor((options.sec_remaining / 60))
    time_sec = options.sec_remaining - (time_min * 60)

    if (time_min >= 60) then
        time_hour = math.floor(time_min / 60)
        time_min = time_min - time_hour * 60
        menu_bar_text = string.format('%d:%02d:%02d', time_hour, time_min, time_sec)
    else
        menu_bar_text = string.format('%d:%02d', time_min, time_sec)
    end

    if (options.is_work_session == true) then
        menu_bar_text = menu_bar_text .. ' | ✎'
    else
        menu_bar_text = menu_bar_text .. ' | ☀'
    end

    if (options.is_pom_timer == true) then
        menu_bar_text = menu_bar_text .. ' ' .. (options.completed_pom_count)
    end

    if (options.timer_message ~= '') then
        menu_bar_text = menu_bar_text .. ' -' .. options.timer_message;
    end

    options.menu_bar_app:setTitle(menu_bar_text)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_disable()
    if (options.current_timer) then
        options.current_timer:stop()
        options.menu_bar_app:delete()
        options.menu_bar_app = nil
        options.current_timer:stop()
        options.current_timer = nil
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_update_time()
    options.sec_remaining = options.sec_remaining - 1

    if (options.sec_remaining <= 0) then
        pom_disable()

        if (options.is_pom_timer) then
            if (options.is_work_session == true) then
                if (options.completed_pom_count % 4 == 0) then
                    hs.notify.new({
                        title = string.format('%.2f', options.initial_min) .. ' work minutes are over',
                        subTitle = 'Starting ' .. string.format('%.2f', LARGE_BREAK_MIN) ..
                            ' minute big break timer',
                        soundName = hs.notify.defaultNotificationSound
                    }):send()
                    options.is_work_session = false
                    pom_enable(LARGE_BREAK_MIN)
                else
                    hs.notify.new({
                        title = string.format('%.2f', options.initial_min) .. ' work minutes are over',
                        subTitle = 'Starting ' .. string.format('%.2f', SMALL_BREAK_MIN) .. ' minute break timer',
                        soundName = hs.notify.defaultNotificationSound
                    }):send()
                    options.is_work_session = false
                    pom_enable(SMALL_BREAK_MIN)
                end
            else
                options.completed_pom_count = options.completed_pom_count + 1

                hs.notify.new({
                    title = string.format('%.2f', options.initial_min) .. ' break minutes are over',
                    subTitle = 'Starting ' .. string.format('%.2f', WORK_MIN) .. ' minute work timer',
                    soundName = hs.notify.defaultNotificationSound
                }):send()
                options.is_work_session = true
                pom_enable(WORK_MIN)
            end
        else
            hs.notify.new({
                title = string.format('%.2f', options.initial_min) .. ' minutes are over',
                soundName = hs.notify.defaultNotificationSound
            }):send()
        end
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_update_menu()
    pom_update_time()
    pom_update_display()
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_create_menu(pom_origin)
    if options.menu_bar_app == nil then
        options.menu_bar_app = hs.menubar.new()
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.pom_enable(minutes, label)
    options.initial_min = minutes
    options.sec_remaining = minutes * 60
    options.timer_message = label or ''

    pom_disable()

    pom_create_menu()
    options.current_timer = hs.timer.doEvery(1, pom_update_menu)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.stop_timers()
    pom_disable()
    options.is_work_session = false
    options.is_pom_timer = false
    options.completed_pom_count = 1
    options.timer_message = ''
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.jump_timer(minutes)
    if options.current_timer then
        options.sec_remaining = options.sec_remaining - (minutes * 60)
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.back_timer(minutes)
    if options.current_timer then
        options.sec_remaining = options.sec_remaining + (minutes * 60)
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.pause_timers()
    if options.current_timer then
        options.current_timer:stop()
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.unpause_timers()
    if options.current_timer then
        options.current_timer = hs.timer.doEvery(1, pom_update_menu)
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.pom_default()
    options.is_work_session = true
    options.is_pom_timer = true
    options.completed_pom_count = 1
    WORK_MIN = 25
    SMALL_BREAK_MIN = 5
    LARGE_BREAK_MIN = 15
    pom_enable(WORK_MIN)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.time_alert_at(time, show)
    options.is_work_session = false
    options.is_pom_timer = false
    new_time = time
    if (hs.fnutils.split(time, ' ')[2] == 'pm') then
        new_hour = tonumber(string.sub(time, 1, 2)) + 12
        new_time = new_hour .. string.sub(time, 3, 5)
    end

    alert_time = hs.timer.seconds(new_time)
    current_time = hs.timer.localTime()
    time_length = alert_time - current_time
    minutes_until_alert = time_length / 60
    if (show) then
        timer_indicator(minutes_until_alert)
    else
        pom_enable(minutes_until_alert)
    end
end
