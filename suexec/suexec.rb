=begin

 Copyright(c) 2008 arton

 Usage of the works is permitted provided that this instrument is retained
 with the works, so that any entity that uses the works is notified of this
 instrument.

 DISCLAIMER: THE WORKS ARE WITHOUT WARRANTY.

=end

require 'cstruct'
require 'fiddle/import'

module SuExec
  extend Fiddle::Importer
  dlload 'shell32.dll'
  extern 'int ShellExecuteExA(void *)', :stdcall

  ShellExecuteInfoA = C::Struct.define {
    DWORD :cbSize;
    ULONG :fMask;
    HANDLE :hwnd;
    PCSTRA :lpVerb;
    PCSTRA :lpFile;
    PCSTRA :lpParameters;
    PCSTRA :lpDirecotry;
    UINT :nShow;
    HANDLE :hInstApp;
    PVOID :lpIDList;
    PCSTRA :lpClass
    HANDLE :hkeyClass;
    ULONG :dwHotKey;
    HANDLE :hIcon;
    HANDLE :hProcess;
  }

  def self.exec(prog, *params)
    ShellExecuteExA(ShellExecuteInfoA.new(ShellExecuteInfoA.size, 0, 0, 
                                          'runas', prog, params.join(' '), '',
                                          1, 0, 0, nil, 0, 0, 0, 0).serialize)
  end
end

if __FILE__ == $0
  SuExec.exec('notepad.exe')
end


