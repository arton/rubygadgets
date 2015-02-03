require 'test/unit'
require 'cstruct'
require 'stringio'

class TestCStruct < Test::Unit::TestCase
  include C

  puts "RawString::VERSION=#{RawString::VERSION}"
  puts "C::Struct::VERSION=#{Struct::VERSION}"

  TestStruct = Struct.define {
    ULONG :u1
    BYTE :b1
  }

  LongLongStruct = Struct.define {
      ULONG :u1
      ULONG :u2
      HFIELD :h1
    }

  def test_longlong()
    u = LongLongStruct.new(2, 2, 90)
    assert_equal('[[:u1, 2], [:u2, 2], [:h1, 90]]', u.inspect)
    u.u1 = 3
    u.u2 = 8
    u.h1 = 9
    assert_equal("\x03\0\0\0\x08\0\0\0\x09\0\0\0\0\0\0\0", u.serialize)
  end
  def test_read_longlong()
    val = StringIO.new("\x03\0\0\0\x08\0\0\0\x09\0\0\0\0\0\0\0")
    u = LongLongStruct.read(val)
    assert_equal(3, u.u1)
    assert_equal(8, u.u2)
    assert_equal(9, u.h1)
  end

  NestClass = Struct.define {
    ULONG :u1
    embed TestCStruct::TestStruct, :t1
  }
  def test_nest()
    u = NestClass.new(0x0100, TestStruct.new(11, 32))
    assert_equal('[[:u1, 256], [:t1, [[:u1, 11], [:b1, 32], [:_filler1, 0]]]]', u.inspect)
    assert_equal("\0\x01\0\0\x0b\0\0\0\x20\0\0\0", u.serialize)
  end

  def test_read_nest()
    val = StringIO.new("\0\x01\0\0\x0b\0\0\0\x20\0\0\0")
    u = NestClass.read(val)
    assert_equal('[[:u1, 256], [:t1, [[:u1, 11], [:b1, 32], [:_filler1, 0]]]]', u.inspect)
  end

  TestStringClass = Struct.define {
    PCSTR :char_ptr
    PCWSTR :wchar_ptr
  }
  def test_rawstring()
    val = StringIO.new(RawString.pointer_test)
    u = TestStringClass.read(val)
    assert_equal('char*', u.char_ptr)
    assert_equal('wchar_t*', u.wchar_ptr.gsub("\0", ''))
  end
end
