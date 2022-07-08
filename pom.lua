-- hs.pom_timer
--
-- A utility for menu bar timers and pomodoro timers, both of which can be
-- paused, unpaused, added to, and subtracted from. Built in combination with
-- Alfred: https://www.alfredapp.com 

pom_timer = {}

local options = {
    current_timer = nil,
    initial_min = 0,
    sec_remaining = 20 * 60,
    timer_message = '',
    is_running = false,
    is_work_timer = false,
    is_break_timer = false,
    is_pom_timer = false,
    total_pom_count = 1
}

local WORK_MIN = 25
local SMALL_BREAK_MIN = 5
local LARGE_BREAK_MIN = 15

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_update_display()
    if (pom_menu) then
        str = ""
        time_min = math.floor((options.sec_remaining / 60))
        time_sec = options.sec_remaining - (time_min * 60)

        if (time_min >= 60) then
            time_hour = math.floor(time_min / 60)
            time_min = time_min - time_hour * 60
            str = string.format("%d:%02d:%02d", time_hour, time_min, time_sec)
        else
            str = string.format("%d:%02d", time_min, time_sec)
        end

        if (options.is_work_timer == true) then
            str = str .. " | ✎"
        else
            if (options.is_break_timer == true) then
                str = str .. " | ☀"
            end
        end

        if (options.is_pom_timer == true) then
            str = str .. " " .. (options.total_pom_count)
        end

        if (options.timer_message ~= '') then
            str = str .. " -" .. options.timer_message;
        end

        pom_menu:setTitle(str)
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_disable()
    pom_was_active = options.is_running
    options.is_running = false

    if (options.current_timer) then
        options.current_timer:stop()
        pom_menu:delete()
        pom_menu = nil
        options.current_timer:stop()
        options.current_timer = nil
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pom_update_time()
    if options.is_running == false then
        return
    else
        options.sec_remaining = options.sec_remaining - 1

        if (options.sec_remaining <= 0) then
            pom_disable()
            if (options.is_work_timer == true) then
                if (options.is_pom_timer == true) then
                    if (options.total_pom_count % 4 == 0) then
                        hs.notify.new({
                            title = string.format("%.2f", options.initial_min) .. " work minutes are over",
                            subTitle = "Starting " .. string.format("%.2f", LARGE_BREAK_MIN) ..
                                " minute big break timer",
                            soundName = hs.notify.defaultNotificationSound
                        }):send()
                        options.is_work_timer = false
                        options.is_break_timer = true
                        pom_enable(LARGE_BREAK_MIN)
                    else
                        hs.notify.new({
                            title = string.format("%.2f", options.initial_min) .. " work minutes are over",
                            subTitle = "Starting " .. string.format("%.2f", SMALL_BREAK_MIN) .. " minute break timer",
                            soundName = hs.notify.defaultNotificationSound
                        }):send()
                        options.is_work_timer = false
                        options.is_break_timer = true
                        pom_enable(SMALL_BREAK_MIN)
                    end
                end
            else
                if (options.is_break_timer == true) then
                    if (options.is_pom_timer == true) then
                        options.total_pom_count = options.total_pom_count + 1
                    end

                    hs.notify.new({
                        title = string.format("%.2f", options.initial_min) .. " break minutes are over",
                        subTitle = "Starting " .. string.format("%.2f", WORK_MIN) .. " minute work timer",
                        soundName = hs.notify.defaultNotificationSound
                    }):send()
                    options.is_work_timer = true
                    options.is_break_timer = false
                    pom_enable(WORK_MIN)
                else
                    hs.notify.new({
                        title = string.format("%.2f", options.initial_min) .. " minutes are over",
                        soundName = hs.notify.defaultNotificationSound
                    }):send()
                end
            end
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
    if pom_menu == nil then
        pom_menu = hs.menubar.new()
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

    options.is_running = true
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.stop_timers()
    pom_disable()
    options.is_work_timer = false
    options.is_break_timer = false
    options.is_pom_timer = false
    options.total_pom_count = 1
    options.timer_message = ''
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.jump_timer(minutes)
    options.sec_remaining = options.sec_remaining - (minutes * 60)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.back_timer(minutes)
    options.sec_remaining = options.sec_remaining + (minutes * 60)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.pause_timers()
    if (options.is_running) then
        options.current_timer:stop()
        options.is_running = false
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.unpause_timers()
    if (not options.is_running) then
        options.current_timer = hs.timer.doEvery(1, pom_update_menu)
        options.is_running = true
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.pom_default()
    options.is_work_timer = true
    options.is_break_timer = false
    options.is_pom_timer = true
    options.total_pom_count = 1
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
    options.is_work_timer = false
    options.is_break_timer = false
    options.is_pom_timer = false
    new_time = time
    if (hs.fnutils.split(time, " ")[2] == "pm") then
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
