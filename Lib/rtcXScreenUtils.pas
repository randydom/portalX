{
  "Screen Utils"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcXScreenUtils;

interface

{$include rtcDefs.inc}

type
  TRtcCaptureSettings=record
    CompleteBitmap:boolean;
    LayeredWindows:boolean;
    AllMonitors:boolean;
    end;

  TMouse_Button = (mb_Left, mb_Right, mb_Middle);

var
  RtcCaptureSettings:TRtcCaptureSettings=(
      CompleteBitmap:True;
      LayeredWindows:True;
      AllMonitors:False);

implementation

end.
