parent=$(dirname $PWD)
export GEM_HOME=$parent/gem
export RUBYLIB=$PWD/lib:$parent/lib:$HOME/lib/ruby
export PATH=${_path:=$PATH}:$PWD/bin:$parent/bin:$GEM_HOME/bin
unset parent

set -u

ns="[$(basename $PWD | sed 's/benry-//')]"

alias t="rake test"
alias ta="rake test:all"
