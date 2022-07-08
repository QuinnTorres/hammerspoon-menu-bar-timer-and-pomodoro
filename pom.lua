-- hs.pom_timer
--
-- A utility for menu bar timers and pomodoro timers, both of which can be
-- paused, unpaused, added to, and subtracted from. Built in combination with
-- Alfred: https://www.alfredapp.com 
pom_timer = {}

local options = {
    current_timer = nil, -- Hammerspoon timer instance
    menu_bar_app = nil, -- Hammerspoon menu bar instance
    initial_minutes = 0, -- Minutes set for the current timer
    seconds_remaining = 0, -- Seconds left until the current timer is done
    timer_message = '', -- Optional message to show to the side of the timer
    is_work_session = false, -- If the current timer is a pomodoro work session
    is_pom_timer = false, -- If the current timer is a pomodoro timer
    completed_pom_count = 0 -- Total number of pomodoros completed
}

-- Default pomodoro timings
-- Work session: 25 minutes
-- Small break session: 5 minutes
-- Large break session: 15 minutes
local WORK_MINUTES = 25
local SMALL_BREAK_MINUTES = 5
local LARGE_BREAK_MINUTES = 15

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function update_menu_bar_text()
    timer_text = get_timer_text(options.seconds_remaining)
    pom_text = get_pom_text()
    get_message_text = get_message_text()

    options.menu_bar_app:setTitle(imer_text .. pom_text .. _message_text)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_disable()
    if options.current_timer then
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
    options.seconds_remaining = options.seconds_remaining - 1

    if options.seconds_remaining <= 0 then
        pom_disable()

        if options.is_pom_timer then
            if options.is_work_session then
                if options.completed_pom_count % 4 == 0 then
                    hs.notify.new({
                        title = string.format('%.2f', options.initial_minutes) .. ' work minutes are over',
                        subTitle = 'Starting ' .. string.format('%.2f', LARGE_BREAK_MINUTES) ..
                            ' minute big break timer',
                        soundName = hs.notify.defaultNotificationSound
                    }):send()
                    options.is_work_session = false
                    pom_enable(LARGE_BREAK_MINUTES)
                else
                    hs.notify.new({
                        title = string.format('%.2f', options.initial_minutes) .. ' work minutes are over',
                        subTitle = 'Starting ' .. string.format('%.2f', SMALL_BREAK_MINUTES) .. ' minute break timer',
                        soundName = hs.notify.defaultNotificationSound
                    }):send()
                    options.is_work_session = false
                    pom_enable(SMALL_BREAK_MINUTES)
                end
            else
                options.completed_pom_count = options.completed_pom_count + 1

                hs.notify.new({
                    title = string.format('%.2f', options.initial_minutes) .. ' break minutes are over',
                    subTitle = 'Starting ' .. string.format('%.2f', WORK_MINUTES) .. ' minute work timer',
                    soundName = hs.notify.defaultNotificationSound
                }):send()
                options.is_work_session = true
                pom_enable(WORK_MINUTES)
            end
        else
            hs.notify.new({
                title = string.format('%.2f', options.initial_minutes) .. ' minutes are over',
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
    update_menu_bar_text()
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
local function get_timer_text(seconds)
    display_minutes = seconds_to_minutes(options.seconds_remaining)
    display_seconds = options.seconds_remaining - minutes_to_seconds(display_minutes)
    display_hours = minutes_to_hours(display_minutes)

    if display_hours > 0 then
        display_minutes = display_minutes - hours_to_minutes(display_hours)
        timer_text = string.format('%d:%02d:%02d', display_hours, display_minutes, display_seconds)
    else
        timer_text = string.format('%d:%02d', display_minutes, display_seconds)
    end

    return timer_text
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function get_pom_text()
    if options.is_pom_timer then
        if options.is_work_session then
            pom_symbol = '✎'
        else
            pom_symbol = '☀'
        end

        return ' | ' .. pom_symbol .. ' ' .. options.completed_pom_count
    else
        return ''
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function get_message_text()
    if options.timer_message ~= '' then
        return ' - ' .. options.timer_message
    else
        return ''
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function minutes_to_hours(minutes)
    return math.floor((minutes / 60))
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function seconds_to_minutes(seconds)
    return math.floor((seconds / 60))
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function minutes_to_seconds(minutes)
    return minutes * 60
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function hours_to_minutes(hours)
    return hours * 60
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.pom_enable(minutes, label)
    options.initial_minutes = minutes
    options.seconds_remaining = minutes_to_seconds(minutes)
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
        options.seconds_remaining = options.seconds_remaining - minutes_to_seconds(minutes)
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.back_timer(minutes)
    if options.current_timer then
        options.seconds_remaining = options.seconds_remaining + minutes_to_seconds(minutes)
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
    WORK_MINUTES = 25
    SMALL_BREAK_MINUTES = 5
    LARGE_BREAK_MINUTES = 15
    pom_enable(WORK_MINUTES)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.time_alert_at(time, show)
    options.is_work_session = false
    options.is_pom_timer = false
    new_time = time
    if hs.fnutils.split(time, ' ')[2] == 'pm' then
        new_hour = tonumber(string.sub(time, 1, 2)) + 12
        new_time = new_hour .. string.sub(time, 3, 5)
    end

    timer_length = seconds_to_minutes(hs.timer.seconds(new_time) - hs.timer.localTime())
    pom_enable(timer_length)
end
