CHANGES
=======


Release 1.0.0 (2023-10-29)
--------------------------

* **[BREAKING CHANGE] gem package name is renamed from 'benry-unixcmd' to 'benry-unixcommand'.**
* [enhance] `sys()` can take an array as commands, for example `sys ["echo", "ABC"]`. This invokes command without shell nor file globbing.
* [change] `sys "echo", "*.txt"` (multiple string arguments) invokes a command without shell, but `sys` globs `*.txt` automatically.
* [enhance] `sys()` now supports `:q` (quiet) option to suppress command echoback. For example `sys "echo ABC"` just prints ABC and not print echoback of command.
* [change] On/off of echoback is determined by `$BENRY_ECHOBACK` and `@__BENRY_ECHOBACK` instead of `BENRY_ECHOBACK` constant.
* [enhance] `echoback_on() { ... }` and `echoback_off() { ... }` are provided to turn echoback on/off temorarily.
* [change] (internally) Default prompt string is changed from `"$"` to `"$ "`.


Release 0.9.0 (2021-09-14)
--------------------------

* First public release
