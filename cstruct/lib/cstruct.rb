=begin

 copyright(c) 2006,2008 arton

 Usage of the works is permitted provided that this instrument is retained
 with the works, so that any entity that uses the works is notified of this
 instrument.

 DISCLAIMER: THE WORKS ARE WITHOUT WARRANTY.

=end

require 'RawString'

module C
  if /64/ =~ RUBY_PLATFORM
    SIZEOF_VOIDP = 8
    PTR_TMPL = 'Q'
  else
    SIZEOF_VOIDP = 4
    PTR_TMPL = 'V'
  end
  # cf. ANSI 3.5.2.1 
  class Struct
    VERSION = '0.1.3'
    class MemberPrototype
      def initialize(type, name, template, size, &block)
        @type_name = type
        @name = name
        @template = template
        @size = size
        @hook = block
      end
      attr_reader :name, :size
      def align
        @size
      end
      def read(f)
        parse(f.read(@size))
      end
      def parse(s)
        puts "parse #{s}, template=#{@template}, name=#{@name}" if $VERBOSE
        v = s.unpack(@template)[0]
        if @hook
          v = @hook.call(v)
        end
        return v
      end
      def serialize(val)
        puts "serialize #{val} into #{@name} with '#{@template}'" if $VERBOSE
        [val].pack(@template)
      end
      def inspact()
        "#{@type_name}: name=#{@name},template=#{@template},size=#{@size}"
      end
    end

    class EmbededMemberPrototype
      def initialize(prototype, name)
        @name = name
        @prototype = prototype
      end
      attr_reader :name
      def size()
        @prototype.size
      end
      def align()
        @prototype.align
      end
      def read(f)
        @prototype.read(f)
      end
      def parse(s)
        @prototype.parse(s)
      end
      def serialize(val)
        val.serialize
      end
    end

    class << Struct

      def define(&block)
        c = Class.new(self)
        c.instance_variable_set(:@prototypes, nil)
        def c.inherited(subclass)
          puts "#{c} inheerited #{subclass}" if $VERBOSE
          proto = @prototypes
          subclass.instance_eval do
            @prototypes = proto
          end
        end
        c.module_eval(&block)
        c.adjust_padding
        c
      end

      def adjust_padding()
        padding(align)
      end
      # pre define some Win32 specific types
      def ULONG(name)
        define_field('ULONG', name, 'L', 4)
      end
      alias DWORD ULONG
      def HANDLE(name)
        define_field('HANDLE', name, PTR_TMPL, SIZEOF_VOIDP)
      end
      def BYTE(name)
        define_field('BYTE', name, 'C', 1)
      end
      def USHORT(name)
        define_field('USHORT', name, 'v', 2)
      end
      alias WORD USHORT
      def UINT(name)
        define_field('UINT', name, 'V', 4)
      end
      def PCSTRA(name)
        define_field('PCSTRA', name, 'p', SIZEOF_VOIDP)
      end
      def PCSTR(name)
        define_field('PCSTR', name, PTR_TMPL, SIZEOF_VOIDP) {|p|
          RawString::load(p)
        }
      end
      def PCWSTR(name)
        define_field('PCWSTR', name, PTR_TMPL, SIZEOF_VOIDP) {|p|
          RawString::wload(p)
        }
      end
      def embed(type, name)
        define_embeded_field(type, name)
      end
      def method_missing(name, *args)
        puts "method_missing name=#{name}, args[0]=#{args[0]}" if $VERBOSE
        if name.to_s[0] != ?P
          #default for long long
          define_field(name, args[0], 'Q', 8)
        else
          define_field(name, args[0], PTR_TMPL, SIZEOF_VOIDP)
        end
      end
      def define_field(type, name, template, size, &block)
        padding(size) unless template[0] == ?x
        (@prototypes ||= []).push MemberPrototype.new(type, name, template, size, &block)
        define_accessor name
      end
      def define_embeded_field(type, name)
        padding(type.align)
        (@prototypes ||= []).push EmbededMemberPrototype.new(type, name)
        define_accessor name
      end
      def padding(boundary)
        r = size % boundary
        if r != 0
          len = boundary - r
          puts "current align=#{boundary}, size=#{size}, pos=#{len}" if $VERBOSE
          @filler = (@filler ||= 0) + 1
          define_field('padding', "_filler#{@filler}".to_sym, "x#{len}", len)
        else
          puts "current align=#{boundary}, size=#{size}" if $VERBOSE
        end
      end
      def define_accessor(name)
        module_eval(<<-End, __FILE__, __LINE__ + 1)
        def #{name}
          self['#{name}']
        end
        def #{name}=(val)
          self['#{name}'] = val
        end
        End
      end

      def inspact()
        @prototypes.inspect
      end

      def names()
        @prototypes.map {|proto| proto.name}
      end
      def size()
        return 0 unless @prototypes
        @prototypes.map {|proto| proto.size }.inject(0) {|sum, s| sum += s }
      end
      def align()
        return 0 unless @prototypes
        @prototypes.map {|proto| (MemberPrototype === proto) ? proto.size : proto.align}.inject(0) {|a, s| (a < s) ? a = s : a }
      end
      def prototypes
        @prototypes
      end
      def read(f)
        new(* @prototypes.map {|proto| proto.read(f) })
      end
    end
    def initialize(*vals)
      i = -1
      nvals = self.class.names.map do |e|
        if e[0] == ?_
          0
        else
          i += 1
          vals[i]
        end
      end
      @alist = self.class.names.zip(nvals)
    end
    def [](name)
      k, v = @alist.assoc(name.to_s.intern)
      raise ArgumentError, "no such field: #{name}" unless k
      v
    end
    def []=(name, val)
      a = @alist.assoc(name.to_s.intern)
      raise ArgumentError, "no such field: #{name}" unless a
      a[1] = val
    end
    def inspect()
      @alist.inspect
    end
    def serialize()
      self.class.prototypes.zip(@alist.map {|dummy, val| val }).map {|proto, val| proto.serialize(val) }.join('')
    end
  end
end
