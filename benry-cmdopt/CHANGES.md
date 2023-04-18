=======
CHANGES
=======


Release 1.2.0 (????-??-??)
--------------------------

* [change] 'Parser#parse()' parses all options even after arguments.
* [enhance] 'Parser#parse(argv, false)' parses options only before arguments.
* [enhance] define '#to_s()' which is alias of '#option_help()'.
* [bugfix] argument '-' will be treated as argument (in before release, '-' is ignored because treated as option).


Release 1.1.0 (2021-01-18)
--------------------------

* [change] rename 'build_option_help()' to 'option_help()'.
* [change] shorten option help width when no long options defined.


Release 1.0.0 (2021-01-17)
--------------------------

* First public release
