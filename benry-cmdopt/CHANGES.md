=======
CHANGES
=======


Release 2.0.0 (????-??-??)
--------------------------

* [change] rename 'Benry::Cmdopt' to 'Benry::CmdOpt', and the old name is still available for backward compatibility.
* [change] `Parser#parse()` parses all options even after arguments.
* [change] keyword parameter `pattern:` is renamed to `rexp:` (`pattern:` is also available for backward compatibilidy).
* [change] `SchemaItem#help` is renamed to `SchemaItem#desc` (old name `#help` is also available for backward compatibility).
* [change] `add(..., type: Integer, enum: ['1','2'])` now raises error because enum contains non-Integer value.
* [enhance] `Parser#parse(argv, false)` parses options only before arguments.
* [enhance] define `#to_s()` which is alias of `#option_help()`.
* [enhance] `Facade#add()` and `Schema#add()` supports `value:` keyword arg for additional value.
* [enhance] regard options which key name starts with '_' as hidden, as well as options which description is nil.
* [enhance] `Facade#dup()` and `Schema#dup()` implemented which duplicates each object.
* [enhance] `Schema#copy_from(other)` implemented which copies option items from other schema.
* [enhance] implemented `Facade#each()` and `Schema#each()` which yields option item.
* [bugfix] treat argument `-` as normal argument (in before release, `-` is ignored because treated as option).
* [bugfix] freeze enum value of `enum:` keyword arg of `Facade#add()` and `Schema#add()`.


Release 1.1.0 (2021-01-18)
--------------------------

* [change] rename `build_option_help()` to `option_help()`.
* [change] shorten option help width when no long options defined.


Release 1.0.0 (2021-01-17)
--------------------------

* First public release
