if hs.ipc.cliStatus() == false then
    hs.ipc.cliInstall()
  end
  
  -----------------------------------------------------------------------------------------
  -- remapping
  
  local FRemap = require('foundation_remapping')
  local remapper = FRemap.new()
  
  -- ; -> return
  remapper:remap(';', 'return')
  -- return -> ;
  remapper:remap('return', ';')
  -- caps lock -> shift
  remapper:remap('capslock', 'lshift')
  -- ctrl -> caps lock
  remapper:remap('lctrl', 'capslock')
  -- tab -> ctrl
  remapper:remap('tab', 'lctrl')
  -- shift -> tab
  remapper:remap('lshift', 'tab')
  
  remapper:register()
  -- remapper:register()
  
  function un_map()
    remapper:unregister()
  end
  
  function map()
    remapper:register()
  end
  -----------------------------------------------------------------------------------------
  
  -----------------------------------------------------------------------------------------
  -- menu bar timer
  -- Timer variables
  
  pom_timer = nil
  
  local pom={}
  
  pom.var = {
    is_active        = false,
    time_left        = 20*60,
    starting_time    = 0,
    is_work          = false,
    is_break         = false,
    is_pom           = false,
    work_time        = 0,
    break_time       = 0,
    big_break_time   = 0,
    pom_count        = 1,
    message          = ''
  }
  
  -- update display
  local function pom_update_display()
    if(pom_menu) then
      local str = ""
      local time_min = math.floor( (pom.var.time_left / 60))
      local time_sec = pom.var.time_left - (time_min * 60)
  
      if(time_min >= 60) then
        local time_hour = math.floor(time_min/60)
        time_min = time_min - time_hour*60
        str = string.format("%d:%02d:%02d", time_hour, time_min, time_sec)
      else
        str = string.format("%d:%02d", time_min, time_sec)
      end
  
      if (pom.var.is_work == true) then
        str = str.." | ✎"
      else
        if (pom.var.is_break == true) then
          str = str.." | ☀"
        end
      end
  
      if (pom.var.is_pom == true) then
        str = str.." "..(pom.var.pom_count)
      end
  
      if (pom.var.message ~= '') then
        str = str.." -"..pom.var.message;
      end
  
      pom_menu:setTitle(str)
    end
  end
  
  -- stop the clock
  function pom_disable()
    local pom_was_active = pom.var.is_active
    pom.var.is_active = false
    if (pom_timer) then
        pom_timer:stop()
        pom_menu:delete()
      pom_menu = nil
      pom_timer:stop()
      pom_timer = nil
    end
  end
  
  -- update pomodoro timer
  local function pom_update_time()
    if pom.var.is_active == false then
      return
    else
      pom.var.time_left = pom.var.time_left - 1
  
      if (pom.var.time_left <= 0 ) then
        pom_disable()
        if (pom.var.is_work == true) then
          if (pom.var.is_pom == true) then
            if (pom.var.pom_count % 4 == 0) then
              hs.notify.new({title=string.format("%.2f", pom.var.starting_time).." work minutes are over", subTitle="Starting "..string.format("%.2f", pom.var.big_break_time).." minute big break timer", soundName=hs.notify.defaultNotificationSound}):send()
              pom.var.is_work = false
              pom.var.is_break = true
              pom_enable(pom.var.big_break_time)
            else
              hs.notify.new({title=string.format("%.2f", pom.var.starting_time).." work minutes are over", subTitle="Starting "..string.format("%.2f", pom.var.break_time).." minute break timer", soundName=hs.notify.defaultNotificationSound}):send()
              pom.var.is_work = false
              pom.var.is_break = true
              pom_enable(pom.var.break_time)
            end
          else
            hs.notify.new({title=string.format("%.2f", pom.var.starting_time).." work minutes are over", subTitle="Starting "..string.format("%.2f", pom.var.break_time).." minute break timer", soundName=hs.notify.defaultNotificationSound}):send()
            pom.var.is_work = false
            pom.var.is_break = true
            pom_enable(pom.var.break_time)
          end
        else
          if (pom.var.is_break == true) then
            if (pom.var.is_pom == true) then
              pom.var.pom_count = pom.var.pom_count + 1
            end
  
            hs.notify.new({title=string.format("%.2f", pom.var.starting_time).." break minutes are over", subTitle="Starting "..string.format("%.2f", pom.var.work_time).." minute work timer", soundName=hs.notify.defaultNotificationSound}):send()
            pom.var.is_work = true
            pom.var.is_break = false
            pom_enable(pom.var.work_time)
          else
            hs.notify.new({title=string.format("%.2f", pom.var.starting_time).." minutes are over", soundName=hs.notify.defaultNotificationSound}):send()
          end
        end
      end
    end
  end
  
  -- update menu display
  local function pom_update_menu()
    pom_update_time()
    pom_update_display()
  end
  
  -- create menu display
  local function pom_create_menu(pom_origin)
    if pom_menu == nil then
      pom_menu = hs.menubar.new()
    end
  end
  
  -- start the pomodoro timer
  function pom_enable(minutes)
    local args = mysplit(minutes, " ");
    local countdownMinutes = tonumber(args[1]);
    local label = '';
  
    pom.var.time_left = countdownMinutes*60;
    pom.var.starting_time = countdownMinutes;
  
    if (args[2] ~= nil) then
      for key, value in pairs(args) do
        if (key > 1) then
          label = label.." "..value;
        end
      end
  
      pom.var.message = label;
    end
  
    pom_disable()
  
    pom_create_menu()
    pom_timer = hs.timer.doEvery(1, pom_update_menu)
  
    pom.var.is_active = true
  end
  -----------------------------------------------------------------------------------------------
  
  -----------------------------------------------------------------------------------------------
  -- pause, unpause, and jump timers
  
  function stop_timers()
    pom_disable()
    pom.var.is_work = false
    pom.var.is_break = false
    pom.var.is_pom = false
    pom.var.pom_count = 1
    pom.var.message = ''
  end
  
  function jump_timer(minutes)
    pom.var.time_left = pom.var.time_left - (minutes * 60)
  end
  
  function back_timer(minutes)
    pom.var.time_left = pom.var.time_left + (minutes * 60)
  end
  
  function pause_timers()
    if(pom.var.is_active) then
      pom_timer:stop()
      pom.var.is_active = false
    end
  end
  
  function unpause_timers()
    if (not pom.var.is_active) then
      pom_timer = hs.timer.doEvery(1, pom_update_menu)
      pom.var.is_active = true
    end
  end
  -----------------------------------------------------------------------------------------------
  
  -----------------------------------------------------------------------------------------------
  -- work timer
  
  function work(minutes)
    pom.var.is_work = true
    pom.var.is_break = false
    pom.var.is_pom = false
    pom.var.work_time = minutes
    pom.var.break_time = minutes / 3
    pom_enable(minutes)
  end
  
  function pom_default()
    pom.var.is_work = true
    pom.var.is_break = false
    pom.var.is_pom = true
    pom.var.pom_count = 1
    pom.var.work_time = 25
    pom.var.break_time = 5
    pom.var.big_break_time = 15
    pom_enable(pom.var.work_time)
  end
  -----------------------------------------------------------------------------------------------
  
  -----------------------------------------------------------------------------------------------
  -- timer (menu bar) until a certain time
  
  function time_alert_at(time, show)
    pom.var.is_work = false
    pom.var.is_break = false
    pom.var.is_pom = false
    new_time = time
    if (hs.fnutils.split(time, " ")[2] == "pm") then
      new_hour = tonumber(string.sub(time,1,2)) + 12
      new_time = new_hour .. string.sub(time,3,5)
    end
  
    alert_time = hs.timer.seconds(new_time)
    current_time = hs.timer.localTime()
    time_length = alert_time - current_time
    minutes_until_alert = time_length/60
    if (show) then
      timer_indicator(minutes_until_alert)
    else
      pom_enable(minutes_until_alert)
    end
  end
  -----------------------------------------------------------------------------------------------
  
  -----------------------------------------------------------------------------------------------
  -- utilities
  function mysplit(inputstr, sep)
          if sep == nil then
                  sep = "%s"
          end
          local t={}
          for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                  table.insert(t, str)
          end
          return t
  end
  -----------------------------------------------------------------------------------------------