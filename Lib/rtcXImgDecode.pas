{
  "RTC Image Decoder"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}
unit rtcXImgDecode;

interface

{$INCLUDE rtcDefs.inc}

uses
  Classes,
  Types,
  SysUtils,

  rtcTypes,
  rtcZLib,

  rtcXCompressRLE,

  rtcXImgConst,
  rtcXBmpUtils,

  rtcXJPEGConst,
  rtcXJPEGDecode;

type
  TRtcImageDecoder=class(TObject)
  private
    JPGHeadStore:RtcByteArray;

    OldBmpInfo, NewBmpInfo: TRtcBitmapInfo;
    FIMGBlockX: integer;
    FIMGBlockY: integer;

    FMotionDebug: boolean;
    FMouseCursor: TRtcMouseCursorInfo;

    procedure ImageItemCopy(left, right: integer);
    procedure SetBlockColor(left:integer; right:LongWord);
    procedure SetMotionDebug(const Value: boolean);

  public
    constructor Create;
    destructor Destroy; override;

    function DecodeMouse(const Data:RtcByteArray):boolean;
    function DecodeSize(const Data:RtcByteArray; var SizeX,SizeY:integer; var Clear:boolean):boolean;
    function Decompress(const Data:RtcByteArray; var BmpInfo:TRtcBitmapInfo):boolean;

    property MotionDebug:boolean read FMotionDebug write SetMotionDebug default False;

    property Cursor:TRtcMouseCursorInfo read FMouseCursor;
    end;

implementation

{ TRtcImageDecoder }

constructor TRtcImageDecoder.Create;
  begin
  inherited Create;
  SetLength(JPGHeadStore,0);
  FMotionDebug:=False;
  FMouseCursor:=TRtcMouseCursorInfo.Create;
  end;

destructor TRtcImageDecoder.Destroy;
  begin
  SetLength(JPGHeadStore,0);
  RtcFreeAndNil(FMouseCursor);
  inherited;
  end;

function TRtcImageDecoder.DecodeSize(const Data: RtcByteArray; var SizeX,SizeY:integer; var Clear:boolean):boolean;
  var
    FDIF, FRLE, FJPG, FMOT, FCUR:boolean;
    haveBmp: boolean;

  begin
  Result:=False;
  Clear:=False;

  if length(Data)<5 then Exit; // no data
  FRLE:=(Data[0] and img_RLE)=img_RLE;
  FJPG:=(Data[0] and img_JPG)=img_JPG;
  FMOT:=(Data[0] and img_MOT)=img_MOT;
  FCUR:=(Data[0] and img_CUR)=img_CUR;
  FDIF:=(Data[0] and img_DIF)=img_DIF;

  if FJPG then
    begin
    if length(Data)<11 then Exit; // data error
    if FRLE then
      begin
      if length(Data)<15 then Exit; // data error
      end;
    haveBmp:=True;
    end
  else if FRLE then
    begin
    if length(Data)<9 then Exit; // data error
    haveBmp:=True;
    end
  else if FMOT then
    begin
    if length(Data)<9 then Exit; // data error
    haveBmp:=True;
    end
  else if FCUR then
    begin
    haveBmp:=False;
    end
  else
    Exit; // no data

  if haveBmp then
    begin
    SizeX:=Data[1]; SizeX:=SizeX shl 8 + Data[2];
    SizeY:=Data[3]; SizeY:=SizeY shl 8 + Data[4];
    Clear:=not FDIF;
    Result:=True;
    end;
  end;

function TRtcImageDecoder.DecodeMouse(const Data: RtcByteArray):boolean;
  begin
  Result:=False;
  if length(Data)<5 then Exit; // no data

  Result:=(Data[0] and img_CUR)=img_CUR;
  end;

function TRtcImageDecoder.Decompress(const Data: RtcByteArray; var BmpInfo: TRtcBitmapInfo):boolean;
  var
    FLZW, FRLE, FJPG, FDIF, FMOT, FCUR:boolean;
    SizeX,SizeY,HeadSize,
    JPGSize,RLESize,MOTSize,CurSize,DataStart,bsize:integer;
    jpgStore, rleStore, motStore, lzwStore, curStore: RtcByteArray;
    haveBmp: boolean;

  procedure MotionDecompensation;
    var
      i,chg,chgLeft,chgRight,chgColor,
      lastLeftID,lastRightID,lastColorID,
      xLeft,yLeft,xRight,yRight,xColor,yColor:integer;
      oldLeftID,oldRightID,
      fromColorID,
      fromLeftID,toLeftID,
      fromRightID,toRightID,
      myLastLeft,myLastRight:integer;
      myLastColor,toColorID,
      myFinalColor:LongWord;

      myBlockLine,
      myBlockX,myBlockY,
      myBlockID,
      maxBlockID,
      maxToBlockID:integer;

      colorBGR:colorBGR32;
      colorRGB:colorRGB32;

    begin
    i:=0;
    FIMGBlockX:=motStore[i]; Inc(i);
    FIMGBlockY:=motStore[i]; Inc(i);

    chgLeft:=motStore[i]; Inc(i);
    chgLeft:=chgLeft shl 8 + motStore[i]; Inc(i);
    chgLeft:=chgLeft shl 8 + motStore[i]; Inc(i);
    // chgLeft:=chgLeft shl 8 + motStore[i]; Inc(i);

    chgRight:=motStore[i]; Inc(i);
    chgRight:=chgRight shl 8 + motStore[i]; Inc(i);
    chgRight:=chgRight shl 8 + motStore[i]; Inc(i);
    // chgRight:=chgRight shl 8 + motStore[i]; Inc(i);

    chg:=(length(motStore)-i) div 6;
    if chgLeft>chg then Exit; // data error!
    if chgRight>chg then Exit; // data error!
    if chgLeft+chgRight>chg then Exit; // data error!

    chgColor:=chg-chgLeft-chgRight;

    lastLeftID:=0;
    lastRightID:=0;
    lastColorID:=0;
    myLastColor:=0;
    myLastLeft:=0;
    myLastRight:=0;
    myBlockLine:=(NewBmpInfo.Width div FIMGBlockX)+1;

    maxBlockID:=(NewBmpInfo.Height div FIMGBLockY)+1;
    maxBlockID:=maxBlockID*myBLockLine;

    maxToBlockID:=NewBmpInfo.Width*(NewBmpInfo.Height-FIMGBlockY) +
                  NewBmpInfo.Width - FIMGBLockX;

    xLeft:=i;
    yLeft:=xLeft+chgLeft*3;
    xRight:=yLeft+chgLeft*3;
    yRight:=xRight+chgRight*3;
    xColor:=yRight+chgRight*3;
    yColor:=xColor+chgColor*3;

    if (chgLeft>0) or (chgRight>0) then
      begin
      OldBmpInfo:=DuplicateBitmapInfo(NewBmpInfo);
      try
        for i:=1 to chgRight do
          begin
          fromRightID:=motStore[xRight];
          fromRightID:=fromRightID shl 8 + motStore[xRight+1];
          fromRightID:=fromRightID shl 8 + motStore[xRight+2];
          // fromRightID:=fromRightID shl 8 + motStore[xRight+3];

          Inc(lastRightID,fromRightID+1);

          myBlockID:=lastRightID-1;
          if myBlockID>=maxBlockID then Exit; // data error!

          myBlockY:=myBlockID div myBlockLine;
          myBlockX:=myBlockID mod myBlockLine;
          myBlockID:=1 + myBlockX*FIMGBLockX + myBlockY*FIMGBlockY*NewBmpInfo.Width;

          toRightID:=motStore[yRight];
          toRightID:=toRightID shl 8 + motStore[yRight+1];
          toRightID:=toRightID shl 8 + motStore[yRight+2];
          // toRightID:=toRightID shl 8 + motStore[yRight+3];

          myLastRight:=myLastRight xor toRightID;
          oldRightID:=myBlockID-myLastRight-1;

          if oldRightID>=maxToBlockID then Exit; // data error!

          ImageItemCopy(-myBlockID,oldRightID);

          Inc(xRight,3);
          Inc(yRight,3);
          end;

        for i:=1 to chgLeft do
          begin
          fromLeftID:=motStore[xLeft];
          fromLeftID:=fromLeftID shl 8 + motStore[xLeft+1];
          fromLeftID:=fromLeftID shl 8 + motStore[xLeft+2];
          // fromLeftID:=fromLeftID shl 8 + motStore[xLeft+3];

          Inc(lastLeftID,fromLeftID+1);

          myBlockID:=lastLeftID-1;
          if myBlockID>=maxBlockID then Exit; // data error!

          myBlockY:=myBlockID div myBlockLine;
          myBlockX:=myBlockID mod myBlockLine;
          myBlockID:=1 + myBlockX*FIMGBLockX + myBlockY*FIMGBlockY*NewBmpInfo.Width;

          toLeftID:=motStore[yLeft];
          toLeftID:=toLeftID shl 8 + motStore[yLeft+1];
          toLeftID:=toLeftID shl 8 + motStore[yLeft+2];
          // toLeftID:=toLeftID shl 8 + motStore[yLeft+3];

          myLastLeft:=myLastLeft xor toLeftID;
          oldLeftID:=myBlockID+myLastLeft+1;

          if oldLeftID>=maxToBlockID then Exit; // data error!

          ImageItemCopy(-myBlockID,oldLeftID);

          Inc(xLeft,3);
          Inc(yLeft,3);
          end;
      finally
        ReleaseBitmapInfo(OldBmpInfo);
        end;
      end;

    for i:=1 to chgColor do
      begin
      fromColorID:=motStore[xColor];
      fromColorID:=fromColorID shl 8 + motStore[xColor+1];
      fromColorID:=fromColorID shl 8 + motStore[xColor+2];
      // fromColorID:=fromColorID shl 8 + motStore[xColor+3];

      Inc(lastColorID,fromColorID+1);
      myBlockID:=lastColorID-1;
      if myBlockID>=maxBlockID then Exit; // data error!

      myBlockY:=myBlockID div myBlockLine;
      myBlockX:=myBlockID mod myBlockLine;
      myBlockID:=1 + myBlockX*FIMGBlockX + myBlockY*FIMGBlockY*NewBmpInfo.Width;

      toColorID:=motStore[yColor];
      toColorID:=toColorID shl 8 + motStore[yColor+1];
      toColorID:=toColorID shl 8 + motStore[yColor+2];
      // toColorID:=toColorID shl 8 + motStore[yColor+3];

      myLastColor:=myLastColor xor toColorID;

      case NewBmpInfo.BuffType of
        btBGRA32:
          begin
          colorBGR.R:=myLastColor and $FF;
          colorBGR.G:=myLastColor shr 8 and $FF;
          colorBGR.B:=myLastColor shr 16 and $FF;
          colorBGR.A:=255;
          myFinalColor:=LongWord(colorBGR);
          end;
        else
          begin
          colorRGB.R:=myLastColor and $FF;
          colorRGB.G:=myLastColor shr 8 and $FF;
          colorRGB.B:=myLastColor shr 16 and $FF;
          colorRGB.A:=255;
          myFinalColor:=LongWord(colorRGB);
          end;
        end;

      SetBlockColor(-myBlockID,myFinalColor);

      Inc(xColor,3);
      Inc(yColor,3);
      end;

    end;

  begin
  Result:=False;

  if length(Data)<5 then Exit; // no data
  FLZW:=(Data[0] and img_LZW)=img_LZW;
  FRLE:=(Data[0] and img_RLE)=img_RLE;
  FJPG:=(Data[0] and img_JPG)=img_JPG;
  FDIF:=(Data[0] and img_DIF)=img_DIF;
  FMOT:=(Data[0] and img_MOT)=img_MOT;
  FCUR:=(Data[0] and img_CUR)=img_CUR;

  HeadSize:=0;
  JPGSize:=0;
  RLESize:=0;
  MOTSize:=0;
  CURSize:=0;

  if FJPG then
    begin
    if length(Data)<11 then Exit; // data error
    HeadSize:=Data[5]; HeadSize:=HeadSize shl 8 + Data[6];
    if FRLE then
      begin
      if length(Data)<15 then Exit; // data error
      JPGSize:=Data[7];
      JPGSize:=JPGSize shl 8 + Data[8];
      JPGSize:=JPGSize shl 8 + Data[9];
      JPGSize:=JPGSize shl 8 + Data[10];
      RLESize:=Data[11];
      RLESize:=RLESize shl 8 + Data[12];
      RLESize:=RLESize shl 8 + Data[13];
      RLESize:=RLESize shl 8 + Data[14];
      DataStart:=15;
      if FMOT then
        MOTSize:=length(Data)-DataStart-JPGSize-RLESize;
      end
    else
      begin
      JPGSize:=Data[7];
      JPGSize:=JPGSize shl 8 + Data[8];
      JPGSize:=JPGSize shl 8 + Data[9];
      JPGSize:=JPGSize shl 8 + Data[10];
      DataStart:=11;
      if FMOT then
        MOTSize:=length(Data)-DataStart-JPGSize;
      end;
    haveBmp:=True;
    end
  else if FRLE then
    begin
    if length(Data)<9 then Exit; // data error
    RLESize:=Data[5];
    RLESize:=RLESize shl 8 + Data[6];
    RLESize:=RLESize shl 8 + Data[7];
    RLESize:=RLESize shl 8 + Data[8];
    DataStart:=9;
    if FMOT then
      MOTSize:=length(data)-DataStart-RLESize;
    haveBmp:=True;
    end
  else if FMOT then
    begin
    if length(Data)<9 then Exit; // data error
    MOTSize:=Data[5];
    MOTSize:=MOTSize shl 8 + Data[6];
    MOTSize:=MOTSize shl 8 + Data[7];
    MOTSize:=MOTSize shl 8 + Data[8];
    DataStart:=9;
    haveBmp:=True;
    end
  else if FCUR then
    begin
    CURSize:=Data[1];
    CURSize:=CURSize shl 8 + Data[2];
    CURSize:=CURSize shl 8 + Data[3];
    CURSize:=CURSize shl 8 + Data[4];
    DataStart:=5;
    haveBmp:=False;
    end
  else
    Exit; // no data

  if haveBmp then
    begin
    SizeX:=Data[1]; SizeX:=SizeX shl 8 + Data[2];
    SizeY:=Data[3]; SizeY:=SizeY shl 8 + Data[4];

    ResizeBitmapInfo(BmpInfo,SizeX,SizeY,not FDIF);

    NewBmpInfo:=MapBitmapInfo(BmpInfo);
    end;

  try
    SetLength(jpgStore,0);
    SetLength(rleStore,0);
    SetLength(motStore,0);
    SetLength(curStore,0);
    if FLZW then
      begin
      if JPGSize>0 then
        begin
        lzwStore:=Copy(Data,DataStart,JPGSize);
        jpgStore:=ZDecompress_Ex(lzwStore);
        Setlength(lzwStore,0);
        end;
      if RLESize>0 then
        begin
        lzwStore:=Copy(Data,DataStart+JPGSize,RLESize);
        rleStore:=ZDecompress_Ex(lzwStore);
        SetLength(lzwStore,0);
        end;
      if MOTSize>0 then
        begin
        lzwStore:=Copy(Data,DataStart+JPGSize+RLESize,MOTSize);
        motStore:=ZDecompress_Ex(lzwStore);
        SetLength(lzwStore,0);
        end;
      if CURSize>0 then
        begin
        lzwStore:=Copy(Data,DataStart+JPGSize+RLESize+MOTSize,CURSize);
        curStore:=ZDecompress_Ex(lzwStore);
        SetLength(lzwStore,0);
        end;
      end
    else
      begin
      if JPGSize>0 then
        jpgStore:=Copy(Data,DataStart,JPGSize);
      if RLESize>0 then
        rleStore:=Copy(Data,DataStart+JPGSize,RLESize);
      if MOTSize>0 then
        motStore:=Copy(Data,DataStart+JPGSize+RLESize,MOTSize);
      if CURSize>0 then
        curStore:=Copy(Data,DataStart+JPGSize+RLESize+MOTSize,CURSize);
      end;

    if length(curStore)>0 then
      begin
      if assigned(FMouseCursor) then
        FMouseCursor.Update(curStore);
      SetLength(curStore,0);
      end;

    if length(motStore)>0 then
      begin
      MotionDecompensation;
      SetLength(motStore,0);
      end;

    if length(jpgStore)>0 then
      begin
      if HeadSize>0 then
        begin
        SetLength(JPGHeadStore,0);
        if FDIF or FRLE then
          Result:=JPEGDiffToBitmap(JPGHeadStore,jpgStore,NewBmpInfo)
        else
          Result:=JPEGToBitmap(jpgStore,NewBmpInfo);
        if Result then
          JPGHeadStore:=Copy(jpgStore,0,HeadSize);
        end
      else
        begin
        if FDIF or FRLE then
          Result:=JPEGDiffToBitmap(JPGHeadStore,jpgStore,NewBmpInfo)
        else
          Result:=JPEGToBitmap(jpgStore,NewBmpInfo);
        end;
      SetLength(jpgStore,0);
      end
    else
      Result:=True;

    if length(rleStore)>0 then
      begin
      if Result then
        begin
        bsize:=NewBmpInfo.BytesPerLine*NewBmpInfo.Height;
        case NewBmpInfo.BuffType of
          btRGBA32:
            RGBA32_Decompress(Addr(rleStore[0]),
                              NewBmpInfo.TopData,
                              length(rleStore),
                              bsize,
                              NewBmpInfo.Width,
                              NewBmpInfo.Height,
                              NewBmpInfo.Reverse);
          btBGRA32:
            BGRA32_Decompress(Addr(rleStore[0]),
                              NewBmpInfo.TopData,
                              length(rleStore),
                              bsize,
                              NewBmpInfo.Width,
                              NewBmpInfo.Height,
                              NewBmpInfo.Reverse);
          end;
        end;
      SetLength(rleStore,0);
      end;
  finally
    if haveBmp then
      UnMapBitmapInfo(NewBmpInfo);
    end;
  end;

procedure TRtcImageDecoder.ImageItemCopy(left, right: integer);
  var
    leftP, rightP: PLongWord;
    leftStride, rightStride,
    movedPixels,
    x,y:integer;
  begin
  if (left<>0) and (right<>0) then
    begin
    if left>0 then
      begin
      leftP:=PLongWord(OldBmpInfo.TopData);
      leftStride:=OldBmpInfo.PixelsToNextLine-FIMGBlockX;
      if OldBmpInfo.Reverse then
        begin
        movedPixels:=(left-1) mod OldBmpInfo.Width;
        Inc(leftP,movedPixels);
        Dec(leftP,(left-1)-movedPixels);
        end
      else
        Inc(leftP,left-1);
      end
    else
      begin
      leftP:=PLongWord(NewBmpInfo.TopData);
      leftStride:=NewBmpInfo.PixelsToNextLine-FIMGBlockX;
      if NewBmpInfo.Reverse then
        begin
        movedPixels:=(-left-1) mod NewBmpInfo.Width;
        Inc(leftP,movedPixels);
        Dec(leftP,(-left-1)-movedPixels);
        end
      else
        Dec(leftP,left+1);
      end;
    if right>0 then
      begin
      rightP:=PLongWord(OldBmpInfo.TopData);
      rightStride:=OldBmpInfo.PixelsToNextLine-FIMGBlockX;
      if OldBmpInfo.Reverse then
        begin
        movedPixels:=(right-1) mod OldBmpInfo.Width;
        Inc(rightP,movedPixels);
        Dec(rightP,(right-1)-movedPixels);
        end
      else
        Inc(rightP,right-1);
      end
    else
      begin
      rightP:=PLongWord(NewBmpInfo.TopData);
      rightStride:=NewBmpInfo.PixelsToNextLine-FIMGBlockX;
      if NewBmpInfo.Reverse then
        begin
        movedPixels:=(-right-1) mod NewBmpInfo.Width;
        Inc(rightP,movedPixels);
        Dec(rightP,(-right-1)-movedPixels);
        end
      else
        Dec(rightP,right+1);
      end;
    if MotionDebug then
      begin
      for y:=1 to FIMGBlockY do
        begin
        for x:=1 to FIMGBlockX do
          begin
          leftP^:=(rightP^ and $FFE0E0E0) or $FF00FF00;
          Inc(leftP);
          Inc(rightP);
          end;
        Inc(leftP,leftStride);
        Inc(rightP,rightStride);
        end;
      end
    else
      begin
      for y:=1 to FIMGBlockY do
        begin
        for x:=1 to FIMGBlockX do
          begin
          leftP^:=rightP^;
          Inc(leftP);
          Inc(rightP);
          end;
        Inc(leftP,leftStride);
        Inc(rightP,rightStride);
        end;
      end;
    end;
  end;

procedure TRtcImageDecoder.SetBlockColor(left:integer; right:LongWord);
  var
    leftP: PLongWord;
    leftStride,
    movedPixels,
    x,y:integer;
  begin
  if left>0 then
    begin
    leftP:=PLongWord(OldBmpInfo.TopData);
    leftStride:=OldBmpInfo.PixelsToNextLine-FIMGBlockX;
    if OldBmpInfo.Reverse then
      begin
      movedPixels:=(left-1) mod OldBmpInfo.Width;
      Inc(leftP,movedPixels);
      Dec(leftP,(left-1)-movedPixels);
      end
    else
      Inc(leftP,left-1);
    end
  else if left<0 then
    begin
    leftP:=PLongWord(NewBmpInfo.TopData);
    leftStride:=NewBmpInfo.PixelsToNextLine-FIMGBlockX;
    if NewBmpInfo.Reverse then
      begin
      movedPixels:=(-left-1) mod NewBmpInfo.Width;
      Inc(leftP,movedPixels);
      Dec(leftP,(-left-1)-movedPixels);
      end
    else
      Dec(leftP,left+1);
    end
  else
    Exit;
  if MotionDebug then right:=(right and $FFE0E0E0) or $FF0000FF;
  for y:=1 to FIMGBlockY do
    begin
    for x:=1 to FIMGBlockX do
      begin
      leftP^:=right;
      Inc(leftP);
      end;
    Inc(leftP,leftStride);
    end;
  end;

procedure TRtcImageDecoder.SetMotionDebug(const Value: boolean);
  begin
  FMotionDebug := Value;
  end;

end.
