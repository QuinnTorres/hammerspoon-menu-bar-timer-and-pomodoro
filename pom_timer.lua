------
-- hs.pom_timer
--
-- A utility for menu bar timers and pomodoro timers, both of which can be
-- paused, unpaused, added to, and subtracted from. Built for use with
-- Alfred: https://www.alfredapp.com and the Hammerspoon Workflow
-- in it: http://www.packal.org/workflow/hammerspoon-workflow

pom_timer = {
    start_timer, -- Start a normal timer in the menu bar (Ex: "30:00 - focus")
    start_pom_timer, -- Start a pomodoro timer in the menu bar (Ex: "25:00 | ✎ 1")
    start_alert_timer, -- Start a normal timer in the menu bar, based on a given alert time (Ex: "25:45 - head out")
    pause_timer, -- Pause the current timer
    unpause_timer, -- Unpause the current timer
    end_timer, -- End the current timer
    add_to_timer, -- Add minutes to the current timer
    subtract_from_timer -- Subtract minutes from the current timer
}

local options = {
    current_timer = nil, -- Hammerspoon timer instance
    menu_bar_app = nil, -- Hammerspoon menu bar instance
    initial_minutes = 0, -- Minutes set for the current timer
    seconds_remaining = 0, -- Seconds left until the current timer is done
    timer_message = '', -- Optional message to show to the side of the timer
    is_work_session = false, -- If the current timer is a pomodoro work session
    is_pom_timer = false, -- If the current timer is a pomodoro timer
    current_pom_count = 0 -- Total number of pomodoros completed
}

------
-- Default pomodoro timings
-- Work session: 25 minutes
-- Small break session: 5 minutes
-- Large break session: 15 minutes
local WORK_MINUTES = 25
local SMALL_BREAK_MINUTES = 5
local LARGE_BREAK_MINUTES = 15
local POMS_UNTIL_LARGE_BREAK = 4
local WORK_LABEL = ' work'
local BREAK_LABEL = ' break'

------
-- Update the text in the menu bar app with the current timer stats
local function update_menu_bar_text()
    timer_text = get_timer_text(options.seconds_remaining)
    pom_text = get_pom_text()
    get_message_text = get_message_text()

    options.menu_bar_app:setTitle(imer_text .. pom_text .. _message_text)
end

------
-- End the current timer session and remove the menu bar app
local function end_timer_session()
    if options.current_timer then
        options.current_timer:stop()
        options.current_timer = nil

        options.menu_bar_app:delete()
        options.menu_bar_app = nil
    end
end

------
-- Decrease the seconds remaining on the timer by 1 and start a new one if necessary
local function update_current_timer()
    options.seconds_remaining = options.seconds_remaining - 1

    if options.seconds_remaining <= 0 then
        end_timer_session()
        notify_and_set_next_timer()
    end
end

------
-- Notify the end of the current timer and start the next one if there is a pomodoro session
local function notify_and_set_next_timer()
    previous_timer_was_work_session = options.is_work_session
    next_timer_minutes = 0

    if options.is_pom_timer then
        if previous_timer_was_work_session then
            next_timer_minutes = SMALL_BREAK_MINUTES
            options.is_work_session = false

            if options.current_pom_count % POMS_UNTIL_LARGE_BREAK == 0 then
                next_timer_minutes = LARGE_BREAK_MINUTES
            end
        else
            next_timer_minutes = WORK_MINUTES
            options.is_work_session = true
            options.current_pom_count = options.current_pom_count + 1
        end

        start_timer(next_timer_minutes)
    end

    send_timer_notification(options.initial_minutes, next_timer_minutes, previous_timer_was_work_session)
end

------
-- Update the timer seconds and the display of it in the menu bar
local function update_timer()
    update_current_timer()
    update_menu_bar_text()
end

------
-- Convert a set of seconds into a timer-friendly display
-- @param seconds the amount of seconds to convert into a timer display
-- @return the timer-friendly string display of the seconds
local function get_timer_text(seconds)
    display_minutes = seconds_to_minutes(options.seconds_remaining)
    display_seconds = options.seconds_remaining - minutes_to_seconds(display_minutes)
    display_hours = minutes_to_hours(display_minutes)

    if display_hours > 0 then
        display_minutes = display_minutes % hours_to_minutes(display_hours)

        return string.format('%d:%02d:%02d', display_hours, display_minutes, display_seconds)
    else
        return string.format('%d:%02d', display_minutes, display_seconds)
    end
end

------
-- Get the pomodoro session icon and completed session counter text
-- @return the pomodoro text
local function get_pom_text()
    if options.is_pom_timer then
        if options.is_work_session then
            pom_symbol = '✎'
        else
            pom_symbol = '☀'
        end

        return ' | ' .. pom_symbol .. ' ' .. options.current_pom_count
    else
        return ''
    end
end

------
-- Get the formatted text for the timer's message
-- @return the message text
local function get_message_text()
    if options.timer_message ~= '' then
        return ' - ' .. options.timer_message
    else
        return ''
    end
end

------
-- Notify the end of the current timer and the start of the next work
-- @param initial_minutes how many minutes the current timer was set for
-- @param next_session_minutes how many minutes the next timer will be set for
-- @param is_work true if the current timer is a pomodoro work session
local function send_timer_notification(initial_minutes, next_session_minutes, is_work)
    title = ''
    sub_title = ''

    session_labels = get_session_labels(next_session_minutes, is_work)
    session_label = session_labels[1]
    next_session_label = session_labels[2]

    title = string.format('%.2f', initial_minutes) .. session_label .. ' minutes are over'

    if next_session_minutes ~= 0 then
        sub_title = 'Starting ' .. string.format('%.2f', next_session_minutes) .. ' minute' .. next_session_label .. ' timer'
    end

    hs.notify.new({
        title = title,
        subTitle = sub_title,
        soundName = hs.notify.defaultNotificationSound
    }):send()
end

------
-- Calculate the session labels to be used in the timer notification
-- @param next_session_minutes the minutes to set for the next timer, 0 if there is no next timer
-- @param is_work if the current timer is a pomodoro work session
-- @return the title and subtitle labels in an array, in that order
local function get_session_labels(next_session_minutes, is_work)
    if next_session_minutes == 0 then
        return {session_label, next_session_label}
    else
        if is_work then
            return {WORK_LABEL, BREAK_LABEL}
        else
            return {BREAK_LABEL, WORK_LABEL}
        end
    end
end

------
-- Convert minutes to hours, rounded
-- @param minutes the number of minutes to convert
-- @return the number of minutes converted to hours
local function minutes_to_hours(minutes)
    return math.floor((minutes / 60))
end

------
-- Convert seconds to minutes, rounded
-- @param seconds the number of seconds to convert
-- @return the number of seconds converted to minutes
local function seconds_to_minutes(seconds)
    return math.floor((seconds / 60))
end

------
-- Convert minutes to seconds
-- @param minutes the number of minutes to convert
-- @return the number of minutes converted to seconds
local function minutes_to_seconds(minutes)
    return minutes * 60
end

------
-- Convert hours to minutes
-- @param hours the number of hours to convert
-- @return the number of hours converted to minutes
local function hours_to_minutes(hours)
    return hours * 60
end

------
-- Start a new timer counting down from a given number of minutes and showing an optional label
-- @param minutes the number of minutes to count down from
-- @param label the optional label to show next to the timer
local function start_timer(minutes, label)
    end_timer()

    options.current_timer = hs.timer.doEvery(1, update_timer)
    options.menu_bar_app = hs.menubar.new()
    options.initial_minutes = minutes
    options.seconds_remaining = minutes_to_seconds(minutes)
    options.timer_message = label or ''
end

------
-- End the entire timer and all sessions
local function end_timer()
    end_timer_session()

    options.is_work_session = false
    options.is_pom_timer = false
    options.current_pom_count = 1
    options.timer_message = ''
end

------
-- Add a specificed number of minutes to the current timer session
-- @param minutes the number of minutes to add
local function add_to_timer(minutes)
    adjust_timer(minutes, false)
end

------
-- Subtract a specificed number of minutes from the current timer session
-- @param minutes the number of minutes to subtract
local function subtract_from_timer(minutes)
    adjust_timer(minutes, true)
end

------
-- Add or subtract a specificed number of minutes to/from the current timer session
-- @param minutes the number of minutes to subtract/add
-- @param should_subtract if the minutes should be subtracted, otherwise added
local function adjust_timer(minutes, should_subtract)
    seconds_to_adjust = minutes_to_seconds(minutes)

    if options.current_timer then
        if should_subtract then
            seconds_to_adjust = seconds_to_adjust * -1
        end

        options.seconds_remaining = options.seconds_remaining + seconds_to_adjust
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function pause_timer()
    if options.current_timer then
        options.current_timer:stop()
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function unpause_timer()
    if options.current_timer then
        options.current_timer = hs.timer.doEvery(1, update_timer)
    end
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function start_pom_timer()
    options.is_work_session = true
    options.is_pom_timer = true
    options.current_pom_count = 1
    WORK_MINUTES = 25
    SMALL_BREAK_MINUTES = 5
    LARGE_BREAK_MINUTES = 15
    start_timer(WORK_MINUTES)
end

------
-- extract standard variables.
-- @param s the string
-- @return @{stdvars}
local function start_alert_timer(time, show)
    options.is_work_session = false
    options.is_pom_timer = false
    new_time = time
    if hs.fnutils.split(time, ' ')[2] == 'pm' then
        new_hour = tonumber(string.sub(time, 1, 2)) + 12
        new_time = new_hour .. string.sub(time, 3, 5)
    end

    timer_length = seconds_to_minutes(hs.timer.seconds(new_time) - hs.timer.localTime())
    start_timer(timer_length)
end
