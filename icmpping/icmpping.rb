=begin
 Copyright(c) 2001,2003 arton, under GPL2.
 
 1.0.1 fix timeout value rounding problem and add checking host address.
       These fixes were formed by Winfried, thanks. 

 1.0.2 fix adress fetch problem when the host without reverse lookup records.
       This fix was contributed by Daniel J. Bell, thanks Daniel.

 1.0.3 support ruby 1.9

== SYNOPSIS
 require 'icmpping'
 result = ICMPPing.ping hostname [, timeout(millisecs) [, packetsize(<1024)]]

== Return Value

 -1 : Any Socket Error
 -2 : Timeout
 >=0: round trip time (in milliseconds)

== Testing Platforms

-1.0.3
 Windows 7

-proior 1.0.3
 Windows2000 (must be Administrator)
 Linux (Vine2.1) (must be root)
 Windows98SE

=end

require 'socket'
require 'timeout'

module ICMPPing
  DEF_PACKET_SIZE = 64
  MAX_PACKET_SIZE = 1024
 private
  def ping(*args) ICMPPing.ping(*args) end
end

begin
  "a"[0] = 64
rescue
  class String
    alias :array_set_org :[]= 
    def []=(i, c)
      if Integer === c
        array_set_org(i, (c & 0xff).chr)
      else
        array_set_org(i, c)
      end
    end
    def &(c)
      if Integer === c
        getbyte(0) & c
      else
        self & c
      end
    end
  end
end  

class << ICMPPing

  IPPROTO_ICMP = 1

  ICMP_ECHO = 8
  ICMP_ECHOREPLY = 0

  def inetaddr(host)
    dest = ''
    TCPSocket.getaddress(host).split(/\./).each do |byte| 
      dest += byte.to_i.chr
    end
    dest
  end

  def ping(host, timeout = 1000, dlen = self::DEF_PACKET_SIZE)

    return -3 if dlen > self::MAX_PACKET_SIZE
    dest = inetaddr(host)
    begin
      hp = [Socket::AF_INET, 0, dest, 0, 0]
    rescue
      $stderr.printf($!.message + "\n") if $VERBOSE
      return -1
    end

    s = Socket.new(Socket::AF_INET, Socket::SOCK_RAW, IPPROTO_ICMP)

    start = tick
    id = $$ & 0xffff
    icmph = [ ICMP_ECHO, 0, 0, id, 0, start.to_i & 0xffffffff, nil ]
    icmph[6] = "E" * dlen
    dat = icmph.pack("C2n3Na*")
    cksum = checksum(((dat.length & 1) ? (dat + "\0") : dat).unpack("n*"))
    dat[2], dat[3] = cksum >> 8, cksum & 0xff
    begin
      s.send dat, 0, hp.pack("v2a*N2")
      timeout(timeout / 1000.0) do
	while true
          rd, rh = s.recvfrom(self::MAX_PACKET_SIZE + 500)
          if String === rh
            rhost = rh.unpack("v2a4")[2]
          else
            rhost = rh.to_sockaddr.unpack("v2a4")[2]
          end  
          icmpdat = rd.slice((rd[0] & 0x0f) * 4..-1)
          resp = icmpdat.unpack("C2n3N")
	  next if resp[0] != ICMP_ECHOREPLY || resp[3] != id || dest != rhost
	  break
	end
      end
    rescue TimeoutError
      $stderr.printf($!.message + "\n") if $VERBOSE
      return -2
    rescue
      $stderr.printf($!.message + "\n") if $VERBOSE
      $stderr.puts($!.backtrace) if $VERBOSE
      return -1
    end

    tick - start
  end

 private
  begin
    require 'Win32API'
    GetTickCount = Win32API.new("kernel32", "GetTickCount", ['V'], 'L')
    def tick
      GetTickCount.call
    end
  rescue LoadError
    def tick
      Time.now.to_f * 1000
    end
  end

  def checksum(n)
    ck = 0
    n.each do |v|
      ck += v
    end
    ck = (ck >> 16) + (ck & 0xffff)
    ck += ck >> 16
    ~ck
  end
end

if $0 == __FILE__
  if ARGV.size <= 0
    print "usage: ping.rb host\n"
    exit 1
  else
    rd = ICMPPing.ping(ARGV[0])
    exit(rd) if rd < 0
    print "#{ICMPPing::DEF_PACKET_SIZE}bytes to #{ARGV[0]} time=#{rd}msec\n"
  end
end
