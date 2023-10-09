parent=`dirname $PWD`
export GEM_HOME=$parent/gem
export RUBYLIB=$PWD/lib:$parent/lib:$HOME/lib/ruby
[ -n "${_path:-}" ] || _path=$PATH
export PATH=$_path:$PWD/bin:$parent/bin:$GEM_HOME/bin
unset parent

alias t="rake test"
alias ta="rake test:all"
