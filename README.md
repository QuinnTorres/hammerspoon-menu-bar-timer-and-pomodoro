# Hammerspoon Pomodoro Timer

## Overview

This [Hammerspoon](https://www.hammerspoon.org) extension can create three different types of minimalist timers in the macOS menu bar: default, pomodoro, and countdown. [Alfred](https://www.alfredapp.com) is a great option for running the extension using the [Hammerspoon Workflow](http://www.packal.org/workflow/hammerspoon-workflow).

For all of the timers, you can also:
- Pause and unpause
- Add minutes while running
- Subtract minutes while running
- Add a label

### Default Timer

For the default timer, provide any amount of minutes (including decimals) and a timer will start counting down in your menu bar. You can also add an optional label. You will get a notification when it's done.

![Alfred - Default Timer](examples/Alfred%20-%20Default%20Timer.png)
> Running the default timer through Alfred

![Alfred - Default Labeled Timer](examples/Alfred%20-%20Default%20Labeled%20Timer.png)
> Running the default timer through Alfred with a label

![Default Timer](examples/Default%20Timer.png)
> Default timer running in the menu bar

![Hammerspoon - Default Timer](examples/Hammerspoon%20-%20Default%20Timer.png)
> Alert once the default timer is done

### Pomodoro Timer

The [Pomodoro Timer](https://en.wikipedia.org/wiki/Pomodoro_Technique) will alternate between 25 minute "work" timers and 5 minute "break" timers. After 4 work timers, the next break will be 15 minutes instead of 5 minutes. You will get a notification when each session ends.

![Alfred - Pomdoro Timer](examples/Alfred%20-%20Pomodoro%20Timer.png)
> Running the pomodoro timer through Alfred

![Pomodoro Timer - Work](examples/Pomodoro%20Timer%20-%20Work.png)
> Pomodoro timer running in the menu bar, in a work session

![Pomodoro Timer - Break](examples/Pomodoro%20Timer%20-%20Break.png)
> Pomodoro timer running in the menu bar, in a break session

![Hammerspoon - Pomodoro Timer](examples/Hammerspoon%20-%20Pomodoro%20Timer.png)
> Alert once the pomodoro timer is done

### Countdown Timer

Provide a 24-hour format time (e.g. "22:00") and a timer will start with the number of minutes between now and the time you specified. You can also add an optional label. You will get a notification when it's done.

![Alfred - Countdown Timer](examples/Alfred%20-%20Countdown%20Timer.png)
> Running the countdown timer through Alfred with a label

![Countdown Timer](examples/Countdown%20Timer.png)
> Countdown timer running in the menu bar
