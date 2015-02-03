require 'pathname'
require 'fiddle/import'

class Pathname

  module WIN32API
    extend Fiddle::Importer
    dlload 'kernel32.dll'    
    extern("int GetShortPathNameA(char* ,char* ,int)", :stdcall)    
  end

  def shortname
    olen = 200
    begin
      buff = ' ' * olen
      len = WIN32API::GetShortPathNameA(relative? ? realpath.to_s : to_s, buff, buff.size)
      if olen < len
        olen = len
      end
    end while olen == len
    buff.rstrip.chomp("\0")
  end
end
  
if $0 == __FILE__
  if ARGV.length == 0
    $stderr.puts 'usage: winpath.rb pathname [more pathname ...]'
    exit 1
  end
  ARGV.each do |f|
    p = Pathname.new(f)
    $stdout.puts p.shortname
  end
end
