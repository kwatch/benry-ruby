# -*- coding: utf-8 -*-
# frozen_string_literal: true

require_relative './shared'


Oktest.scope do


  topic Benry::CmdOpt::SchemaItem do

    ITEMS = [
      Benry::CmdOpt::SchemaItem.new(:help, "-h, --help", "help msg",
                                    "h", "help", nil, nil),
      Benry::CmdOpt::SchemaItem.new(:file, "-f, --file=<file>", "filename",
                                    "f", "file", "<file>", true),
      Benry::CmdOpt::SchemaItem.new(:indent, "-i, --indent[=<N>]", "indent width",
                                    "i", "indent", "<N>", false),
    ]


    topic '#initialize()' do

      before do
        @schema = Benry::CmdOpt::Schema.new
      end

      spec "[!nn4cp] freezes enum object." do
        item = Benry::CmdOpt::SchemaItem.new(:foo, "--foo", "desc", nil, "foo", "<val>",
                                             true, enum: ["x", "y", "z"])
        ok {item.enum} == ["x", "y", "z"]
        ok {item.enum}.frozen?
      end

      case_when "[!wy2iv] when 'type:' specified..." do

        spec "[!7xmr5] raises SchemaError when type is not registered." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent[=<WIDTH>]", "indent width", type: Array)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "Array: Unregistered type.")
        end

        spec "[!s2aaj] raises SchemaError when option has no params but type specified." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent", "indent width", type: Integer)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "Integer: Type specified in spite of option has no params.")
        end

        spec "[!sz8x2] not raise error when no params but value specified." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent", "indent width", type: Integer, value: 0)
          }
          ok {pr}.NOT.raise?(Exception)
        end

        spec "[!70ogf] not raise error when no params but TrueClass specified." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent", "indent width", type: TrueClass)
          }
          ok {pr}.NOT.raise?(Exception)
        end

      end

      case_when "[!6y8s2] when 'rexp:' specified..." do

        spec "[!bi2fh] raises SchemaError when pattern is not a regexp." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-x, --indent[=<WIDTH>]", "indent width", rexp: '\A\d+\z')
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         '"\\\\A\\\\d+\\\\z": Regexp pattern expected.')
        end

        spec "[!01fmt] raises SchmeaError when option has no params but pattern specified." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i, --indent", "indent width", rexp: /\A\d+\z/)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         '/\A\d+\z/: Regexp pattern specified in spite of option has no params.')
        end

      end

      case_when "[!5nrvq] when 'enum:' specified..." do

        spec "[!melyd] raises SchemaError when enum is not an Array nor Set." do
          sc = @schema
          sc.add(:indent1, "-i <N>", "indent width", enum: ["2", "4", "8"])
          sc.add(:indent2, "-j <N>", "indent width", enum: Set.new(["2", "4", "8"]))
          pr = proc {
            sc.add(:indent3, "-k <N>", "indent width", enum: "2,4,8")
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         '"2,4,8": Array or set expected.')
        end

        spec "[!xqed8] raises SchemaError when enum specified for no param option." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i", "enable indent", enum: [2, 4, 8])
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "[2, 4, 8]: Enum specified in spite of option has no params.")
        end

        spec "[!zuthh] raises SchemaError when enum element value is not instance of type class." do
          sc = @schema
          pr = proc {
            sc.add(:indent, "-i <N>", "enable indent", type: Integer, enum: ['2', '4', '8'])
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         '["2", "4", "8"]: Enum element value should be instance of Integer, but "2" is not.')
        end

      end

      case_when "[!hk4nw] when 'range:' specified..." do

        spec "[!z20ky] raises SchemaError when range is not a Range object." do
          pr = proc {
            @schema.add(:indent, "-i <N>", "indent", type: Integer, range: [1,8])
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "[1, 8]: Range object expected.")
        end

        spec "[!gp025] raises SchemaError when range specified with `type: TrueClass`." do
          pr = proc {
            @schema.add(:indent, "-i <N>", "indent", type: TrueClass, range: 0..1)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "0..1: Range is not available with `type: TrueClass`.")
        end

        spec "[!7njd5] range beginning/end value should be expected type." do
          pr = proc {
            @schema.add(:indent, "-i <N>", "indent", range: (1..8))
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "1..8: Range value should be String, but not.")
          pr = proc {
            @schema.add(:indent, "-i <N>", "indent", type: Date, range: (1..8))
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "1..8: Range value should be Date, but not.")
        end

        spec "[!uymig] range object can be endless." do
          begin
            range1 = eval "(1..)"    # Ruby >= 2.6
            range2 = eval "(..3)"    # Ruby >= 2.6
          rescue SyntaxError
            range1 = nil             # Ruby < 2.6
            range2 = nil             # Ruby < 2.6
          end
          if range1
            pr = proc {
              @schema.add(:indent1, "-i <N>", "indent", type: Integer, range: range1)
              @schema.add(:indent2, "-j <N>", "indent", type: Integer, range: range2)
            }
            ok {pr}.NOT.raise?(Exception)
          end
        end

      end

      case_when "[!a0g52] when 'value:' specified..." do

        spec "[!435t6] raises SchemaError when 'value:' is specified on argument-required option." do
          sc = @schema
          pr = proc {
            sc.add(:flag, "--flag=<on|off>", "flag", type: TrueClass, value: true)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "true: 'value:' is meaningless when option has required argument (hint: change to optional argument instead).")
        end

        spec "[!6vwqv] raises SchemaError when type is TrueClass but value is not true nor false." do
          sc = @schema
          pr = proc {
            sc.add(:flag, "--flag[=<on|off>]", "flag", type: TrueClass, value: 0)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "0: Value should be true or false when `type: TrueClass` specified.")
        end

        spec "[!c6i2o] raises SchemaError when value is not a kind of type." do
          sc = @schema
          pr = proc {
            sc.add(:flag, "--flag[=<on|off>]", "flag", type: Integer, value: false)
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "Type mismatched between `type: Integer` and `value: false`.")
        end

        spec "[!lnhp6] not raise error when type is not specified." do
          sc = @schema
          pr = proc {
            sc.add(:flag, "--flag[=<on|off>]", "flag", value: false)
          }
          ok {pr}.NOT.raise?(Exception)
        end

        spec "[!6xb8o] value should be included in enum values." do
          sc = @schema
          pr = proc {
            sc.add(:lang, "--lang[=<en|fr|it>]", "language", enum: ["en", "fr", "it"], value: "ja")
          }
          ok {pr}.raise?(Benry::CmdOpt::SchemaError,
                         "ja: Value should be included in enum values, but not.")
        end

      end

    end


    topic '#required?' do

      spec "[!svxny] returns nil if option takes no arguments." do
        item, _, _ = ITEMS
        ok {item.required?} == nil
      end

      spec "[!togcx] returns true if argument is required." do
        _, item, _ = ITEMS
        ok {item.required?} == true
      end

      spec "[!uwbgc] returns false if argument is optional." do
        _, _, item = ITEMS
        ok {item.required?} == false
      end

    end


    topic '#arg_requireness()' do

      spec "[!kmo28] returns :none if option takes no arguments." do
        item, _, _ = ITEMS
        ok {item.arg_requireness()} == :none
      end

      spec "[!s8gxl] returns :required if argument is required." do
        _, item, _ = ITEMS
        ok {item.arg_requireness()} == :required
      end

      spec "[!owpba] returns :optional if argument is optional." do
        _, _, item = ITEMS
        ok {item.arg_requireness()} == :optional
      end

    end


    topic '#multiple?()' do

      spec "[!1lj8v] returns true if @multiple is truthy." do
        item = Benry::CmdOpt::SchemaItem.new(:includes, "-I <path>", "include path", "I", nil, nil, nil, multiple: true)
        ok {item.multiple?} == true
        item = Benry::CmdOpt::SchemaItem.new(:includes, "-I <path>", "include path", "I", nil, nil, nil, multiple: 123)
        ok {item.multiple?} == true
      end

      spec "[!cun23] returns false if @multiple is falthy." do
        item = Benry::CmdOpt::SchemaItem.new(:includes, "-I <path>", "include path", "I", nil, nil, nil, multiple: false)
        ok {item.multiple?} == false
        item = Benry::CmdOpt::SchemaItem.new(:includes, "-I <path>", "include path", "I", nil, nil, nil, multiple: nil)
        ok {item.multiple?} == false
      end

    end


    topic '#hidden?()' do

      spec "[!no6ov] returns true if @hidden is true." do
        item = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil, hidden: true)
        ok {item.hidden?} == true
      end

      spec "[!ej8ot] returns false if @hidden is false." do
        item = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil, hidden: false)
        ok {item.hidden?} == false
      end

      spec "[!h0uxs] returns true if desc is nil." do
        desc = nil
        item = Benry::CmdOpt::SchemaItem.new(:debug, "-D", desc, "D", nil, nil, nil)
        ok {item.hidden?} == true
      end

      spec "[!28vzx] returns false if else." do
        desc = "debug mode"
        item = Benry::CmdOpt::SchemaItem.new(:debug, "-D", desc, "D", nil, nil, nil)
        ok {item.hidden?} == false
      end

    end


    topic '#important?()' do

      spec "[!ua8kt] returns true/false if `important:` kwarg passed to constructor." do
        item1 = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil, important: true)
        ok {item1.important?} == true
        item2 = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil, important: false)
        ok {item2.important?} == false
      end

      spec "[!hz9sx] returns nil if `important:` kwarg not passed to constructor." do
        item3 = Benry::CmdOpt::SchemaItem.new(:debug, "-D", "debug mode", "D", nil, nil, nil)
        ok {item3.important?} == nil
      end

    end


    topic '#validate_and_convert()' do

      def new_item(key, optstr, desc, short, long, param, required,
                   type: nil, rexp: nil, enum: nil, range: nil, value: nil, &callback)
        return Benry::CmdOpt::SchemaItem.new(key, optstr, desc, short, long, param, required,
                   type: type, rexp: rexp, enum: enum, range: range, value: value, &callback)
      end

      spec "[!h0s0o] raises RuntimeError when value not matched to pattern." do
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, rexp: /\A\d+\z/)
        optdict = {}
        pr = proc { x.validate_and_convert("abc", optdict) }
        ok {pr}.raise?(RuntimeError, "Pattern unmatched.")
      end

      spec "[!5jrdf] raises RuntimeError when value not in enum." do
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, enum: ['2', '4', '8'])
        optdict = {}
        pr = proc { x.validate_and_convert("10", optdict) }
        ok {pr}.raise?(RuntimeError, "Expected one of 2/4/8.")
      end

      spec "[!5falp] raise RuntimeError when value not in range." do
        x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                     type: Integer, range: 2..8)
        optdict = {}
        pr = proc { x.validate_and_convert("1", optdict) }
        ok {pr}.raise?(RuntimeError, "Too small (min: 2)")
        pr = proc { x.validate_and_convert("9", optdict) }
        ok {pr}.raise?(RuntimeError, "Too large (max: 8)")
        ## when min==0
        x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                     type: Integer, range: 0..8)
        optdict = {}
        pr = proc { x.validate_and_convert("-1", optdict) }
        ok {pr}.raise?(RuntimeError, "Positive value (>= 0) expected.")
        ## when min==1
        x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                     type: Integer, range: 1..8)
        optdict = {}
        pr = proc { x.validate_and_convert("0", optdict) }
        ok {pr}.raise?(RuntimeError, "Positive value (>= 1) expected.")
      end

      spec "[!a0rej] supports endless range." do
        begin
          range1 = eval "(2..)"     # Ruby >= 2.6
          range2 = eval "(..8)"
        rescue SyntaxError
          range1 = nil              # Ruby < 2.6
          range2 = nil
        end
        if range1
          x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                       type: Integer, range: range1)
          optdict = {}
          pr = proc { x.validate_and_convert("1", optdict) }
          ok {pr}.raise?(RuntimeError, "Too small (min: 2)")
          pr = proc { x.validate_and_convert("9", optdict) }
          ok {pr}.NOT.raise?(RuntimeError)
        end
        if range2
          x = new_item(:indent, "-i[=<N>]", "indent", "i", nil, "<N>", false,
                       type: Integer, range: range2)
          optdict = {}
          pr = proc { x.validate_and_convert("1", optdict) }
          ok {pr}.NOT.raise?(RuntimeError)
          pr = proc { x.validate_and_convert("9", optdict) }
          ok {pr}.raise?(RuntimeError, "Too large (max: 8)")
        end
      end

      spec "[!j4fuz] calls type-specific callback when type specified." do
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, type: Integer)
        optdict = {}
        pr = proc { x.validate_and_convert("abc", optdict) }
        ok {pr}.raise?(RuntimeError, "Integer expected.")
      end

      spec "[!jn9z3] calls callback when callback specified." do
        called = false
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false) {|va|
          called = true
        }
        optdict = {}
        x.validate_and_convert("abc", optdict)
        ok {called} == true
      end

      spec "[!iqalh] calls callback with different number of args according to arity." do
        args1 = nil
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false) {|val|
          args1 = val
        }
        optdict = {}
        x.validate_and_convert("123", optdict)
        ok {args1} == "123"
        #
        args2 = nil
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false) {|optdict, key, val|
          args2 = [optdict, key, val]
        }
        optdict = {}
        x.validate_and_convert("123", optdict)
        ok {args2} == [optdict, :indent, "123"]
      end

      spec "[!x066l] returns new value." do
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, type: Integer)
        ok {x.validate_and_convert("123", {})} == 123
        #
        x = new_item(:indent, "", "indent width", "i", "indent", "<WIDTH>", false, type: Integer) {|val|
          val * 2
        }
        ok {x.validate_and_convert("123", {})} == 246
      end

      spec "[!eafem] returns default value (if specified) instead of true value." do
        x1 = new_item(:flag, "", "desc", "f", "flag", nil, false, value: nil)
        ok {x1.validate_and_convert(true, {})} == true
        x2 = new_item(:flag, "", "desc", "f", "flag", nil, false, value: "blabla")
        ok {x2.validate_and_convert(true, {})} == "blabla"
        x3 = new_item(:flag, "", "desc", "f", "flag", nil, false, value: false)
        ok {x3.validate_and_convert(true, {})} == false
      end

    end

  end


end
