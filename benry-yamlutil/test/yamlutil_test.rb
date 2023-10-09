# -*- coding: utf-8 -*-


require 'oktest'

require 'benry/yamlutil'


Oktest.scope do


  topic Benry::YAMLUtil do

    classmap = {
      "teams"    => Struct.new('Team',   'name', 'members', 'leader'),
      "members"  => Struct.new('Member', 'name', 'gender', 'team'),
    }

    input_string = <<-'END'
      teams:
        - name: SOS Brigade
          members:
            - {name: Haruhi, gender: F}
            - {name: Kyon,   gender: M}
            - {name: Mikuru, gender: F}
            - {name: Itsuki, gender: M}
            - {name: Yuki,   gender: F}
    END


    topic '.load()' do

      spec "supports custom class map." do
        ydoc = Benry::YAMLUtil.load(input_string, classmap)
        #
        ok {ydoc}                           .is_a?(Hash)
        ok {ydoc['teams'][0]}               .is_a?(classmap["teams"])
        ok {ydoc['teams'][0]['members'][0]} .is_a?(classmap["members"])
        #
        team = ydoc['teams'][0]
        ok {team.name}              == 'SOS Brigade'
        ok {team.members[0].name}   == 'Haruhi'
        ok {team.members[0].gender} == 'F'
      end

      spec "supports default class by '*'." do
        magic_hash_cls = Class.new(Hash) do
          def method_missing(method, *args)
            return super unless args.empty?
            return self[method.to_s]
          end
        end
        classmap2 = {'*' => magic_hash_cls}
        #
        ydoc = Benry::YAMLUtil.load(input_string, classmap2)
        #
        ok {ydoc}                           .is_a?(magic_hash_cls)
        ok {ydoc['teams'][0]}               .is_a?(magic_hash_cls)
        ok {ydoc['teams'][0]['members'][0]} .is_a?(magic_hash_cls)
        #
        team = ydoc['teams'][0]
        ok {team.name}              == "SOS Brigade"
        ok {team.members[0].name}   == "Haruhi"
        ok {team.members[0].gender} == "F"
      end

      spec "has no error on merging mapping." do
        input = <<-END
        column-defaults:
          - &id
            name  : id
            type  : int
            pkey  : true
        tables:
          - name  : admin_users
            columns:
              - <<: *id
                name:  user_id
        END
        classmap3 = {
          "tables"  => Struct.new('Table', 'name', 'columns'),
          "columns" => Struct.new('Column', 'name', 'type', 'pkey', 'required'),
        }
        #
        ydoc = Benry::YAMLUtil.load(input, classmap3)
        #
        ok {ydoc['tables'][0]}               .is_a?(classmap3["tables"])
        ok {ydoc['tables'][0]['columns'][0]} .is_a?(classmap3["columns"])
        #
        table = ydoc['tables'][0]
        ok {table.columns[0].type} == 'int'       # merged
        ok {table.columns[0].pkey} == true        # merged
        ok {table.columns[0].name} == 'user_id'   # ovrerwritten
      end


      input_string2 = <<-END
        teams:
          - &sos
            name: SOS Brigade
            leader:  *haruhi    # alias (appeared before anchor)
            members:
              - &haruhi         # anchor
                {name: Haruhi, team: *sos}
              - {name: Kyon  , team: *sos}
      END

      spec "supports lazy alias feature with custom classes." do
        input = input_string2
        ydoc = nil
        pr = proc { ydoc = Benry::YAMLUtil.load(input, classmap) }
        ok {pr}.NOT.raise?(Exception)
        ok {ydoc['teams'][0].leader.name}          == "Haruhi"
        ok {ydoc['teams'][0].members[0].name}      == "Haruhi"
        ok {ydoc['teams'][0].members[0].team.name} == "SOS Brigade"
      end

      spec "supports lazy alias feature with Hash class." do
        input = input_string2
        ydoc = nil
        pr = proc { ydoc = Benry::YAMLUtil.load(input) }
        ok {pr}.NOT.raise?(Exception)
        ok {ydoc['teams'][0]['leader']}                     .is_a?(Hash)
        ok {ydoc['teams'][0]['members'][0]['team']}         .is_a?(Hash)
        ok {ydoc['teams'][0]['leader']['name']}             == "Haruhi"
        ok {ydoc['teams'][0]['members'][0]['name']}         == "Haruhi"
        ok {ydoc['teams'][0]['members'][0]['team']['name']} == "SOS Brigade"
      end

      spec "raises error when anchor is missing." do
        input = input_string2.sub('*haruhi', '*harupin')
        ydoc = nil
        pr = proc { ydoc = Benry::YAMLUtil.load(input, classmap) }
        ok {pr}.raise?(Psych::BadAlias, "Unknown alias: harupin")
      end

      spec "raises error when merging anchor missing." do
        input = <<-'END'
        - <<: *a1
        - &a1
          name: AAA
        END
        ydoc = nil
        pr = proc { ydoc = Benry::YAMLUtil.load(input, classmap) }
        ok {pr}.raise?(Psych::BadAlias, "Anchor '&a1' should appear before '<<: *a1'")
      end


    end


  end


end
