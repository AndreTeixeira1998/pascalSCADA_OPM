unit server_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  mutexserver;

type

  { TForm1 }

  TForm1 = class(TForm)
    Label1: TLabel;
    MutexServer1: TMutexServer;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

end.

