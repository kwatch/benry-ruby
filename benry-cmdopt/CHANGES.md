=======
CHANGES
=======


Release 2.0.0 (????-??-??)
--------------------------

* [change] rename 'Benry::Cmdopt' to 'Benry::CmdOpt', and the old name is still available for backward compatibility.
* [change] `Parser#parse()` parses all options even after arguments.
* [change] treat argument `-` as normal argument (in before release, `-` is ignored because treated as option).
* [change] keyword parameter `pattern:` is renamed to `rexp:` (`pattern:` is also available for backward compatibilidy).
* [change] `SchemaItem#help` is renamed to `SchemaItem#desc` (old name `#help` is also available for backward compatibility).
* [change] `add(..., type: Integer, enum: ['1','2'])` now raises error because enum contains non-Integer value.
* [change] freeze enum value of `enum:` keyword arg of `Facade#add()` and `Schema#add()`.
* [enhance] `Parser#parse(argv, false)` parses options only before arguments.
* [enhance] define `#to_s()` which is alias of `#option_help()`.
* [enhance] `Facade#add()` and `Schema#add()` supports `range:` keyword arg which validates option value.
* [enhance] `Facade#add()` and `Schema#add()` supports `value:` keyword arg for additional value.
* [enhance] `Facade#add()` and `Schema#add()` supports `detail:` keyword arg for detailed description.
* [enhance] `Facade#add()` and `Schema#add()` supports `tag:` keyword arg which accepts arbitrary value.
* [enhance] regard options which key name starts with '_' as hidden, as well as options which description is nil.
* [enhance] add `Schema#get()` which finds option item by key name.
* [enhance] add `Schema#delete()` which deletes option item by key name.
* [enhance] add `Schema#each()` which yields option items.
* [enhance] add `Schema#empty?(all: true)` which returns true if schema has no option items.
* [enhance] add `Schema#dup()` which duplicates each object.
* [enhance] add `Schema#copy_from(other)` which copies option items from other schema.


Release 1.1.0 (2021-01-18)
--------------------------

* [change] rename `build_option_help()` to `option_help()`.
* [change] shorten option help width when no long options defined.


Release 1.0.0 (2021-01-17)
--------------------------

* First public release
