------
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

------
-- Default pomodoro timings
-- Work session: 25 minutes
-- Small break session: 5 minutes
-- Large break session: 15 minutes
local WORK_MINUTES = 25
local SMALL_BREAK_MINUTES = 5
local LARGE_BREAK_MINUTES = 15

local WORK_LABEL = 'work'
local BREAK_LABEL = 'break'

------
-- Update the text in the menu bar app with the current timer stats
local function update_menu_bar_text()
    timer_text = get_timer_text(options.seconds_remaining)
    pom_text = get_pom_text()
    get_message_text = get_message_text()

    options.menu_bar_app:setTitle(imer_text .. pom_text .. _message_text)
end

------
-- End the current timer and remove the menu bar app
local function end_current_timer()
    if options.current_timer then
        options.current_timer:stop()
        options.current_timer = nil

        options.menu_bar_app:delete()
        options.menu_bar_app = nil
    end
end

------
-- Decrease the seconds remaining on the timer by 1 and start a new one if
-- necessary
local function pom_update_time()
    options.seconds_remaining = options.seconds_remaining - 1

    if options.seconds_remaining <= 0 then
        end_current_timer()
        set_next_timer()
    end
end

local function set_next_timer()
    next_timer_minutes = 0

    if options.is_pom_timer then
        if options.is_work_session then
            should_start_large_break = options.completed_pom_count % 4 == 0
            options.is_work_session = false

            if should_start_large_break then
                next_timer_minutes = LARGE_BREAK_MINUTES
            else
                next_timer_minutes = SMALL_BREAK_MINUTES
            end

            send_timer_notification(options.initial_minutes, next_timer_minutes, true)
        else
            options.completed_pom_count = options.completed_pom_count + 1
            next_timer_minutes = WORK_MINUTES
            options.is_work_session = true

            hs.notify.new({
                title = string.format('%.2f', options.initial_minutes) .. ' break minutes are over',
                subTitle = 'Starting ' .. string.format('%.2f', WORK_MINUTES) .. ' minute work timer',
                soundName = hs.notify.defaultNotificationSound
            }):send()
        end

        pom_enable(next_timer_minutes)
    else
        hs.notify.new({
            title = string.format('%.2f', options.initial_minutes) .. ' minutes are over',
            soundName = hs.notify.defaultNotificationSound
        }):send()
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
local function send_timer_notification(initial_minutes, next_session_minutes, is_work)
    title = ''
    sub_title = ''
    session_label = ''
    next_session_label = ''

    if is_work then
        session_label = WORK_LABEL
        next_session_label = BREAK_LABEL
    else
        session_label = BREAK_LABEL
        next_session_label = WORK_LABEL
    end

    title = string.format('%.2f', initial_minutes) .. ' ' .. session_label .. ' minutes are over'

    if next_session_minutes then
        sub_title = 'Starting ' .. string.format('%.2f', next_session_minutes) .. ' minute ' .. next_session_label .. ' timer'
    end

    hs.notify.new({
        title = title,
        subTitle = sub_title,
        soundName = hs.notify.defaultNotificationSound
    }):send()
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

    end_current_timer()

    pom_create_menu()
    options.current_timer = hs.timer.doEvery(1, pom_update_menu)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
function pom_timer.stop_timers()
    end_current_timer()
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
