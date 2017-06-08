{
  "RLE RGB Compression"
  - Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  @exclude
}

unit rtcXCompressRLE;

interface

uses
  SysUtils,
  rtcTypes,

  rtcXJPEGConst;

{$INCLUDE rtcDefs.inc}

function RGBA32_Compress(const LastBlock, NowBlock, DestBlock: pointer; ImgWidth, ImgHeight: word; ImgReverse:boolean): longword;

function RGBA32_Decompress(const SrcBlock, DestBlock: pointer; const SrcLen, BlockSize: longword; ImgWidth, ImgHeight:word; ImgReverse:boolean): boolean;

function BGRA32_Compress(const LastBlock, NowBlock, DestBlock: pointer; ImgWidth, ImgHeight: word; ImgReverse:boolean): longword;

function BGRA32_Decompress(const SrcBlock, DestBlock: pointer; const SrcLen, BlockSize: longword; ImgWidth, ImgHeight:word; ImgReverse:boolean): boolean;

implementation

type
  PLongWord = ^longword;
  PWord = ^Word;
  PByte = ^Byte;

  TRGB = packed record
    R,G,B:byte;
    end;
  PRGB = ^TRGB;

  TBGR = packed record
    B,G,R:byte;
    end;
  PBGR = ^TBGR;

  TRGBA = packed record
    R,G,B,A:byte;
    end;
  PRGBA = ^TRGBA;

  TBGRA = packed record
    B,G,R,A:byte;
    end;
  PBGRA = ^TBGRA;

  // Memory reserved by "DestBlock" needs to be at least 2 x BlockSize bytes
  // Result = number of bytes writen to DestBlock
function RGBA32_Compress(const LastBlock, NowBlock, DestBlock: pointer; ImgWidth, ImgHeight: word; ImgReverse:boolean): longword;
var
  ptrNow, ptrLast,
  ptrDest, ptrStart,
  ptrLastDest: ^Byte;

  cnt_dword: longint;
  cnt_lines: longint;
  EAX, EBX, ECX, EDX: longword;
  ESI, EDI: PLongWord;
  ByteEDI: PByte absolute EDI;
  WordEDI: PWord absolute EDI;
  EDIBits: PRGB absolute EDI; // Source RGB

  EAXBits: TRGB absolute EAX; // Dest RGB

  ptrLastSafe, ptrNowSafe: ^longword;
begin
  ptrDest := DestBlock; // Destination image
  ptrLastDest := ptrDest;

  ptrLastSafe := LastBlock;
  ptrNowSafe := NowBlock;
  cnt_lines := ImgHeight;

  repeat
    { Codes:
      #0 = next line
      #251 + count:word = skip (word) count*4 bytes

      #252 + count:byte + value:RGB = repeat RGB pixel (byte) count times
      #253 + count:word + value:RGB = repeat RGB pixel (word) count times

      #254 + count:byte + data = copy (byte) count RGB pixels of data
      #255 + count:word + data = copy (word) count RGB pixels of data

      count:byte (1..250) = skip (byte) RGB pixels }

    if not CompareMem(ptrNowSafe,ptrLastSafe,ImgWidth*4) then
      begin
      ptrStart:=ptrDest;
      ptrLast := Pointer(ptrLastSafe); // Old image
      ptrNow := Pointer(ptrNowSafe); // New image
      cnt_dword := ImgWidth; // Image Width in pixels

      ECX := cnt_dword;
      ESI := PLongWord(ptrNow);
      EDI := PLongWord(ptrLast);
      repeat
        { We need:
          ECX = cnt_dword (number of dwords left to check
          ESI = ptrNow position to start scanning
          EDI = ptrLast position to start scanning }

        { Count where equal ... }

        EDX := ECX; // number of dwords to check

        // Count all Equal dwords
        repeat
          if EDI^ = ESI^ then
          begin
            Inc(EDI);
            Inc(ESI);
            Dec(ECX);
          end
          else
            Break;
        until ECX = 0;

        if ECX = 0 then // all that's left is equal
          Break;

        Dec(EDX, ECX); // number of dwords where "source=dest"

        if EDX > 0 then
        begin // moved?
          { * if we have equal bytes, do ... * }

          ptrNow := pointer(ESI); // update ptrNow
          ptrLast := pointer(EDI); // update ptrLast and store EDI

          { Write jump-header ... }
          EDI := PLongWord(ptrDest);

          if EDX <= 250 then
          begin
            // ByteEDI := PByte(EDI);
            ByteEDI^ := EDX;
            Inc(ByteEDI);

            // EDI := PLongWord(ByteEDI);
          end
          else
          begin
            // ByteEDI := PByte(EDI);
            ByteEDI^ := 251;
            Inc(ByteEDI);

            // WordEDI := PWord(ByteEDI);
            WordEDI^ := EDX;
            Inc(WordEDI);

            // EDI := PLongWord(WordEDI);
          end;
          ptrDest := pointer(EDI); // update ptrDest

          EDI := PLongWord(ptrLast); // restore EDI
        end; { * done equal dwords. * }

        { Count where not equal ... }
        EDX := ECX; // EDX = dwords left to check

        // Count all un-equal drowds
        repeat
          if EDI^ <> ESI^ then
          begin
            Inc(EDI);
            Inc(ESI);
            Dec(ECX);
          end
          else
            Break;
        until ECX = 0;

        if ECX > 0 then // found equal dwords?
          Dec(EDX, ECX); // EDX = Non-Equal count

        cnt_dword := ECX; // update cnt_dword to dwords left to check on next run
        ptrLast := pointer(EDI); // update ptrLast for next run

        { ------------------
          Copy changed data ...
          ------------------ }

        { until here, we've prepared:
          - cnt_dword & ptrLast for the next run (if there will be one)
          - ptrNow to first non-equal longword position
          - ptrDest to next writing position
          - EDX to number of non-equal dwords to check and compress }

        // prepare ESI & ECX for iterations using LODSD
        ECX := EDX; // ECX = non-equal longword count

        // @count_repeating:
        repeat
          { from here, we need:
            ECX = dwords left to check
            ptrNow & ptrDest point to current source & dest location }

          { Count how many times "EAX" is repeating ... }

          EDI := PLongWord(ptrNow); // EDI = first non-equal longword position
          EDX := ECX; // dwords left to check
          EAX := EDI^; // load first longword (will scan for this one)

          while ECX>0 do
            begin
            Inc(EDI);
            Dec(ECX);
            if EDI^ <> EAX then
              Break;
            end;

          Dec(EDX, ECX); // repeating dwords count

          if EDX > 1 then
          begin
            ptrNow := pointer(EDI);
            // update ptrNow (behind last repeating longword)

            { from here, we need:
              ptrNow = position after last repeating longword
              EAX = repeating longword (data)
              EDX = number of times EAX is repeating
              ECX = number of dwords left to check (non-repeating)
              EDI = ptrNow location behind last equal longword }

            { Write info about compressed dwords ... }
            EDI := PLongWord(ptrDest); // get ptrDest
            { write repeating header }
            if EDX <= $FF then
            begin
              // ByteEDI := PByte(EDI);
              ByteEDI^ := 252;
              Inc(ByteEDI);
              ByteEDI^ := EDX;
              Inc(ByteEDI);

              // EDI := PLongWord(ByteEDI);
              EDIBits^.R := EAXBits.R;
              EDIBits^.G := EAXBits.G;
              EDIBits^.B := EAXBits.B;
              Inc(EDIBits);
            end
            else
            begin
              // ByteEDI := PByte(EDI);
              ByteEDI^ := 253;
              Inc(ByteEDI);

              // WordEDI := PWord(ByteEDI);
              WordEDI^ := EDX;
              Inc(WordEDI);

              // EDI := PLongWord(WordEDI);
              EDIBits^.R := EAXBits.R;
              EDIBits^.G := EAXBits.G;
              EDIBits^.B := EAXBits.B;
              Inc(EDIBits);
            end;

            ptrDest := pointer(EDI); // update ptrDest

            // EDX:=ECX;                     // dwords left to check
          end
          else
          begin
            { from here, we need:
              ptrDest = next writing position
              ptrNow = next ptrNow longword to check
              ECX = number of non-equal dwords left - 1
              EDX = number of dwords checked }

            if ECX > 0 then // one longword can't be compressed.
            begin
              ESI := PLongWord(ptrNow);
              Inc(EDX, ECX);
              { Check how many dwords we can't compress using RLE }
              repeat
                EAX := ESI^; // store last longword
                Inc(ESI); // load next longword
                if ESI^ = EAX then // longwords match? done.
                begin
                  Inc(ECX);
                  Break;
                end;
                Dec(ECX);
              until ECX = 0;
              Dec(EDX, ECX); // EDX = non-repeating longword count
            end;

            { from here, we need:
              ECX = number of dwords left to check (if >0, count repeating)
              EDX = number of non-repeating dwords to copy
              ptrNow & ptrDest point to current source & dest location }

            EBX := ECX; // EBX = save ECX (non-equal dwords left to check)

            ECX := EDX; // ECX = dwords to copy
            ESI := PLongWord(ptrNow); // read from ptrNow
            EDI := PLongWord(ptrDest); // write to ptrDest

            { Write "EDX" dwords down }
            // write normal header ...
            if EDX <= $FF then
            begin
              // ByteEDI := PByte(EDI);
              ByteEDI^ := 254;
              Inc(ByteEDI);

              ByteEDI^ := EDX;
              Inc(ByteEDI);

              // EDI := PLongWord(ByteEDI);
            end
            else
            begin
              // ByteEDI := PByte(EDI);
              ByteEDI^ := 255;
              Inc(ByteEDI);

              // WordEDI := PWord(ByteEDI);
              WordEDI^ := EDX;
              Inc(WordEDI);

              // EDI := PLongWord(WordEDI);
            end;

            repeat
              EAX:=ESI^;
              EDIBits^.R:=EAXBits.R;
              EDIBits^.G:=EAXBits.G;
              EDIBits^.B:=EAXBits.B;
              Inc(EDIBits);
              Inc(ESI);
              Dec(ECX);
              until ECX=0;

            ptrNow := pointer(ESI);
            ptrDest := pointer(EDI);

            ECX := EBX; // restore ECX (dwords left to check)
          end;
        until ECX = 0;
        // have repeating dwords ...

        ESI := PLongWord(ptrNow);
        EDI := PLongWord(ptrLast);
        ECX := cnt_dword;
      until ECX = 0;

      if ptrStart<>ptrDest then // have data?
        ptrLastDest := ptrDest;
      end;

    ptrDest^ := 0;
    Inc(ptrDest);

    Dec(cnt_lines);
    if cnt_lines=0 then
      Break
    else if ImgReverse then
      begin
      Dec(ptrLastSafe,ImgWidth);
      Dec(ptrNowSafe,ImgWidth);
      end
    else
      begin
      Inc(ptrLastSafe,ImgWidth);
      Inc(ptrNowSafe,ImgWidth);
      end;
  until False;

  Result := RtcIntPtr(ptrLastDest) - RtcIntPtr(DestBlock);
end;

function RGBA32_Decompress(const SrcBlock, DestBlock: pointer; const SrcLen, BlockSize: longword; ImgWidth, ImgHeight:word; ImgReverse:boolean): boolean;
var
  id: ^Byte;
  b: ^Byte absolute id;
  w: ^Word absolute id;
  dw: ^longword absolute id;
  bcnt: Byte;
  wcnt: Word;

  len: longword;
  pixDest, pixOrig: ^LongWord;

  srcRGB:PRGB absolute id; // Source RGB

  dstRGB:PRGB absolute pixDest; // Dest RGB
  fillRGB:longword;
  tmpRGB:TRGBA absolute fillRGB; // Fill RGB

  procedure FillDWord(fill: longword; data: pointer; cnt: longword);
  var
    a: longword;
    longdata: PLongWord absolute data;
  begin
    for a := 1 to cnt do
    begin
      longdata^ := fill;
      Inc(longdata);
    end;
  end;

  procedure CopyDWord(from,data: pointer; cnt: longword);
  var
    a: longword;
    srcData: PRGB absolute from;
    dstData: PRGBA absolute data;
  begin
    for a := 1 to cnt do
    begin
      dstData^.A:=255;
      dstData^.R:=srcData^.R;
      dstData^.G:=srcData^.G;
      dstData^.B:=srcData^.B;
      Inc(srcData);
      Inc(dstData);
    end;
  end;

begin
  Result := True;

  len := SrcLen;
  id := SrcBlock;
  pixOrig := DestBlock;

  { Codes:
    #0 = next line
    #251 + count:word = skip (word) count*4 bytes

    #252 + count:byte + value:RGB = repeat RGB pixel (byte) count times
    #253 + count:word + value:RGB = repeat RGB pixel (word) count times

    #254 + count:byte + data = copy (byte) count RGB pixels of data
    #255 + count:word + data = copy (word) count RGB pixels of data

    count:byte (1..250) = skip (byte) RGB pixels }

  tmpRGB.A:=255;

  pixDest := pixOrig;
  while (len > 0) do
  begin
    case id^ of
      0: // next line
        begin
        Inc(id);
        Dec(len);
        if imgReverse then
          Dec(pixOrig,ImgWidth)
        else
          Inc(pixOrig,ImgWidth);
        pixDest:=pixOrig;
        end;
      251: // count:word = skip count*4 bytes
        begin
          Inc(id);
          Dec(len);

          wcnt := w^; // get count
          Inc(id, 2);
          Dec(len, 2);

          Assert(longword(pixDest) - longword(pixOrig) + wcnt * 4 <= BlockSize);

          Inc(pixDest, wcnt);
        end;
      252: // count:byte + value:RGB = repeat RGB pixel count times
        begin
          Inc(id);
          Dec(len);

          bcnt := b^; // get byte count
          Inc(id);
          Dec(len);

          tmpRGB.R:=srcRGB^.R;
          tmpRGB.G:=srcRGB^.G;
          tmpRGB.B:=srcRGB^.B;
          Inc(id, 3);
          Dec(len, 3);

          Assert(longword(pixDest) - longword(pixOrig) + bcnt * 4 <= BlockSize);

          FillDWord(fillRGB, pixDest, bcnt);

          Inc(pixDest, bcnt);
        end;
      253: // count:word + value:RGB = repeat RGB pixel count times
        begin
          Inc(id);
          Dec(len);

          wcnt := w^; // get word count
          Inc(id, 2);
          Dec(len, 2);

          tmpRGB.R:=srcRGB^.R;
          tmpRGB.G:=srcRGB^.G;
          tmpRGB.B:=srcRGB^.B;
          Inc(id, 3);
          Dec(len, 3);

          Assert(longword(pixDest) - longword(pixOrig) + wcnt * 4 <= BlockSize);

          FillDWord(fillRGB, pixDest, wcnt);

          Inc(pixDest, wcnt);
        end;
      254: // count:byte + data = copy (byte) count RGB pixels of data
        begin
          Inc(id);
          Dec(len);

          bcnt := b^; // get count
          Inc(id);
          Dec(len);

          Assert((len >= bcnt * 3) and (longword(pixDest) - longword(pixOrig) + bcnt * 4 <= BlockSize));

          CopyDWord(id, pixDest, bcnt);

          Inc(id, bcnt * 3);
          Dec(len, bcnt * 3);

          Inc(pixDest, bcnt);
        end;
      255: // count:word + data = copy (word) count RGB pixels of data
        begin
          Inc(id);
          Dec(len);

          wcnt := w^; // get count
          Inc(id, 2);
          Dec(len, 2);

          Assert((len >= wcnt * 3) and (longword(pixDest) - longword(pixOrig) + wcnt * 4 <= BlockSize));

          CopyDWord(id, pixDest, wcnt);

          Inc(id, wcnt * 3);
          Dec(len, wcnt * 3);

          Inc(pixDest, wcnt);
        end;
    else // count:byte (1..250) = skip count*4 bytes
      begin
        bcnt := b^;
        Inc(id);
        Dec(len);

        Assert((longword(pixDest) - longword(pixOrig) + bcnt * 4) <= BlockSize);

        Inc(pixDest, bcnt);
      end;
    end;
  end;
end;

  // Memory reserved by "DestBlock" needs to be at least 2 x BlockSize bytes
  // Result = number of bytes writen to DestBlock
function BGRA32_Compress(const LastBlock, NowBlock, DestBlock: pointer; ImgWidth, ImgHeight: word; ImgReverse:boolean): longword;
var
  ptrNow, ptrLast,
  ptrDest, ptrStart,
  ptrLastDest: ^Byte;

  cnt_dword: longint;
  cnt_lines: longint;
  EAX, EBX, ECX, EDX: longword;
  ESI, EDI: PLongWord;
  ByteEDI: PByte absolute EDI;
  WordEDI: PWord absolute EDI;
  EDIBits: PRGB absolute EDI; // Dest RGB

  EAXBits: TBGR absolute EAX; // Source BGR

  ptrLastSafe, ptrNowSafe: ^longword;
begin
  ptrDest := DestBlock; // Destination image
  ptrLastDest := ptrDest;

  ptrLastSafe := LastBlock;
  ptrNowSafe := NowBlock;
  cnt_lines := ImgHeight;

  repeat
    { Codes:
      #0 = next line
      #251 + count:word = skip (word) count*4 bytes

      #252 + count:byte + value:RGB = repeat RGB pixel (byte) count times
      #253 + count:word + value:RGB = repeat RGB pixel (word) count times

      #254 + count:byte + data = copy (byte) count RGB pixels of data
      #255 + count:word + data = copy (word) count RGB pixels of data

      count:byte (1..250) = skip (byte) RGB pixels }

    if not CompareMem(ptrNowSafe,ptrLastSafe,ImgWidth*4) then
      begin
      ptrStart:=ptrDest;
      ptrLast := Pointer(ptrLastSafe); // Old image
      ptrNow := Pointer(ptrNowSafe); // New image
      cnt_dword := ImgWidth; // Image Width in pixels

      ECX := cnt_dword;
      ESI := PLongWord(ptrNow);
      EDI := PLongWord(ptrLast);
      repeat
        { We need:
          ECX = cnt_dword (number of dwords left to check
          ESI = ptrNow position to start scanning
          EDI = ptrLast position to start scanning }

        { Count where equal ... }

        EDX := ECX; // number of dwords to check

        // Count all Equal dwords
        repeat
          if EDI^ = ESI^ then
          begin
            Inc(EDI);
            Inc(ESI);
            Dec(ECX);
          end
          else
            Break;
        until ECX = 0;

        if ECX = 0 then // all that's left is equal
          Break;

        Dec(EDX, ECX); // number of dwords where "source=dest"

        if EDX > 0 then
        begin // moved?
          { * if we have equal bytes, do ... * }

          ptrNow := pointer(ESI); // update ptrNow
          ptrLast := pointer(EDI); // update ptrLast and store EDI

          { Write jump-header ... }
          EDI := PLongWord(ptrDest);

          if EDX <= 250 then
          begin
            // ByteEDI := PByte(EDI);
            ByteEDI^ := EDX;
            Inc(ByteEDI);

            // EDI := PLongWord(ByteEDI);
          end
          else
          begin
            // ByteEDI := PByte(EDI);
            ByteEDI^ := 251;
            Inc(ByteEDI);

            // WordEDI := PWord(ByteEDI);
            WordEDI^ := EDX;
            Inc(WordEDI);

            // EDI := PLongWord(WordEDI);
          end;
          ptrDest := pointer(EDI); // update ptrDest

          EDI := PLongWord(ptrLast); // restore EDI
        end; { * done equal dwords. * }

        { Count where not equal ... }
        EDX := ECX; // EDX = dwords left to check

        // Count all un-equal drowds
        repeat
          if EDI^ <> ESI^ then
          begin
            Inc(EDI);
            Inc(ESI);
            Dec(ECX);
          end
          else
            Break;
        until ECX = 0;

        if ECX > 0 then // found equal dwords?
          Dec(EDX, ECX); // EDX = Non-Equal count

        cnt_dword := ECX; // update cnt_dword to dwords left to check on next run
        ptrLast := pointer(EDI); // update ptrLast for next run

        { ------------------
          Copy changed data ...
          ------------------ }

        { until here, we've prepared:
          - cnt_dword & ptrLast for the next run (if there will be one)
          - ptrNow to first non-equal longword position
          - ptrDest to next writing position
          - EDX to number of non-equal dwords to check and compress }

        // prepare ESI & ECX for iterations using LODSD
        ECX := EDX; // ECX = non-equal longword count

        // @count_repeating:
        repeat
          { from here, we need:
            ECX = dwords left to check
            ptrNow & ptrDest point to current source & dest location }

          { Count how many times "EAX" is repeating ... }

          EDI := PLongWord(ptrNow); // EDI = first non-equal longword position
          EDX := ECX; // dwords left to check
          EAX := EDI^; // load first longword (will scan for this one)

          while ECX>0 do
            begin
            Inc(EDI);
            Dec(ECX);
            if EDI^ <> EAX then
              Break;
            end;

          Dec(EDX, ECX); // repeating dwords count

          if EDX > 1 then
          begin
            ptrNow := pointer(EDI);
            // update ptrNow (behind last repeating longword)

            { from here, we need:
              ptrNow = position after last repeating longword
              EAX = repeating longword (data)
              EDX = number of times EAX is repeating
              ECX = number of dwords left to check (non-repeating)
              EDI = ptrNow location behind last equal longword }

            { Write info about compressed dwords ... }
            EDI := PLongWord(ptrDest); // get ptrDest
            { write repeating header }
            if EDX <= $FF then
            begin
              // ByteEDI := PByte(EDI);
              ByteEDI^ := 252;
              Inc(ByteEDI);
              ByteEDI^ := EDX;
              Inc(ByteEDI);

              // EDI := PLongWord(ByteEDI);
              EDIBits^.R := EAXBits.R;
              EDIBits^.G := EAXBits.G;
              EDIBits^.B := EAXBits.B;
              Inc(EDIBits);
            end
            else
            begin
              // ByteEDI := PByte(EDI);
              ByteEDI^ := 253;
              Inc(ByteEDI);

              // WordEDI := PWord(ByteEDI);
              WordEDI^ := EDX;
              Inc(WordEDI);

              // EDI := PLongWord(WordEDI);
              EDIBits^.R := EAXBits.R;
              EDIBits^.G := EAXBits.G;
              EDIBits^.B := EAXBits.B;
              Inc(EDIBits);
            end;

            ptrDest := pointer(EDI); // update ptrDest

            // EDX:=ECX;                     // dwords left to check
          end
          else
          begin
            { from here, we need:
              ptrDest = next writing position
              ptrNow = next ptrNow longword to check
              ECX = number of non-equal dwords left - 1
              EDX = number of dwords checked }

            if ECX > 0 then // one longword can't be compressed.
            begin
              ESI := PLongWord(ptrNow);
              Inc(EDX, ECX);
              { Check how many dwords we can't compress using RLE }
              repeat
                EAX := ESI^; // store last longword
                Inc(ESI); // load next longword
                if ESI^ = EAX then // longwords match? done.
                begin
                  Inc(ECX);
                  Break;
                end;
                Dec(ECX);
              until ECX = 0;
              Dec(EDX, ECX); // EDX = non-repeating longword count
            end;

            { from here, we need:
              ECX = number of dwords left to check (if >0, count repeating)
              EDX = number of non-repeating dwords to copy
              ptrNow & ptrDest point to current source & dest location }

            EBX := ECX; // EBX = save ECX (non-equal dwords left to check)

            ECX := EDX; // ECX = dwords to copy
            ESI := PLongWord(ptrNow); // read from ptrNow
            EDI := PLongWord(ptrDest); // write to ptrDest

            { Write "EDX" dwords down }
            // write normal header ...
            if EDX <= $FF then
            begin
              // ByteEDI := PByte(EDI);
              ByteEDI^ := 254;
              Inc(ByteEDI);

              ByteEDI^ := EDX;
              Inc(ByteEDI);

              // EDI := PLongWord(ByteEDI);
            end
            else
            begin
              // ByteEDI := PByte(EDI);
              ByteEDI^ := 255;
              Inc(ByteEDI);

              // WordEDI := PWord(ByteEDI);
              WordEDI^ := EDX;
              Inc(WordEDI);

              // EDI := PLongWord(WordEDI);
            end;

            repeat
              EAX:=ESI^;
              EDIBits^.R:=EAXBits.R;
              EDIBits^.G:=EAXBits.G;
              EDIBits^.B:=EAXBits.B;
              Inc(EDIBits);
              Inc(ESI);
              Dec(ECX);
              until ECX=0;

            ptrNow := pointer(ESI);
            ptrDest := pointer(EDI);

            ECX := EBX; // restore ECX (dwords left to check)
          end;
        until ECX = 0;
        // have repeating dwords ...

        ESI := PLongWord(ptrNow);
        EDI := PLongWord(ptrLast);
        ECX := cnt_dword;
      until ECX = 0;

      if ptrStart<>ptrDest then // have data?
        ptrLastDest := ptrDest;
      end;

    ptrDest^ := 0;
    Inc(ptrDest);

    Dec(cnt_lines);
    if cnt_lines=0 then
      Break
    else if ImgReverse then
      begin
      Dec(ptrLastSafe,ImgWidth);
      Dec(ptrNowSafe,ImgWidth);
      end
    else
      begin
      Inc(ptrLastSafe,ImgWidth);
      Inc(ptrNowSafe,ImgWidth);
      end;
  until False;

  Result := RtcIntPtr(ptrLastDest) - RtcIntPtr(DestBlock);
end;

function BGRA32_Decompress(const SrcBlock, DestBlock: pointer; const SrcLen, BlockSize: longword; ImgWidth, ImgHeight:word; ImgReverse:boolean): boolean;
var
  id: ^Byte;
  b: ^Byte absolute id;
  w: ^Word absolute id;
  dw: ^longword absolute id;
  bcnt: Byte;
  wcnt: Word;

  len: longword;
  pixDest, pixOrig: ^LongWord;

  srcRGB:PRGB absolute id; // Source RGB

  dstRGB:PBGR absolute pixDest; // Dest BGR
  fillRGB:longword;
  tmpRGB:TBGRA absolute fillRGB; // Fill BGR

  procedure FillDWord(fill: longword; data: pointer; cnt: longword);
  var
    a: longword;
    longdata: PLongWord absolute data;
  begin
    for a := 1 to cnt do
    begin
      longdata^ := fill;
      Inc(longdata);
    end;
  end;

  procedure CopyDWord(from,data: pointer; cnt: longword);
  var
    a: longword;
    srcData: PRGB absolute from; // Source RGB
    dstData: PBGRA absolute data; // Dest BGR
  begin
    for a := 1 to cnt do
    begin
      dstData^.A:=255;
      dstData^.R:=srcData^.R;
      dstData^.G:=srcData^.G;
      dstData^.B:=srcData^.B;
      Inc(srcData);
      Inc(dstData);
    end;
  end;

begin
  Result := True;

  len := SrcLen;
  id := SrcBlock;
  pixOrig := DestBlock;

  { Codes:
    #0 = next line
    #251 + count:word = skip (word) count*4 bytes

    #252 + count:byte + value:RGB = repeat RGB pixel (byte) count times
    #253 + count:word + value:RGB = repeat RGB pixel (word) count times

    #254 + count:byte + data = copy (byte) count RGB pixels of data
    #255 + count:word + data = copy (word) count RGB pixels of data

    count:byte (1..250) = skip (byte) RGB pixels }

  tmpRGB.A:=255;

  pixDest := pixOrig;
  while (len > 0) do
  begin
    case id^ of
      0: // next line
        begin
        Inc(id);
        Dec(len);
        if imgReverse then
          Dec(pixOrig,ImgWidth)
        else
          Inc(pixOrig,ImgWidth);
        pixDest:=pixOrig;
        end;
      251: // count:word = skip count*4 bytes
        begin
          Inc(id);
          Dec(len);

          wcnt := w^; // get count
          Inc(id, 2);
          Dec(len, 2);

          Assert(longword(pixDest) - longword(pixOrig) + wcnt * 4 <= BlockSize);

          Inc(pixDest, wcnt);
        end;
      252: // count:byte + value:RGB = repeat RGB pixel count times
        begin
          Inc(id);
          Dec(len);

          bcnt := b^; // get byte count
          Inc(id);
          Dec(len);

          tmpRGB.R:=srcRGB^.R;
          tmpRGB.G:=srcRGB^.G;
          tmpRGB.B:=srcRGB^.B;
          Inc(id, 3);
          Dec(len, 3);

          Assert(longword(pixDest) - longword(pixOrig) + bcnt * 4 <= BlockSize);

          FillDWord(fillRGB, pixDest, bcnt);

          Inc(pixDest, bcnt);
        end;
      253: // count:word + value:RGB = repeat RGB pixel count times
        begin
          Inc(id);
          Dec(len);

          wcnt := w^; // get word count
          Inc(id, 2);
          Dec(len, 2);

          tmpRGB.R:=srcRGB^.R;
          tmpRGB.G:=srcRGB^.G;
          tmpRGB.B:=srcRGB^.B;
          Inc(id, 3);
          Dec(len, 3);

          Assert(longword(pixDest) - longword(pixOrig) + wcnt * 4 <= BlockSize);

          FillDWord(fillRGB, pixDest, wcnt);

          Inc(pixDest, wcnt);
        end;
      254: // count:byte + data = copy (byte) count RGB pixels of data
        begin
          Inc(id);
          Dec(len);

          bcnt := b^; // get count
          Inc(id);
          Dec(len);

          Assert((len >= bcnt * 3) and (longword(pixDest) - longword(pixOrig) + bcnt * 4 <= BlockSize));

          CopyDWord(id, pixDest, bcnt);

          Inc(id, bcnt * 3);
          Dec(len, bcnt * 3);

          Inc(pixDest, bcnt);
        end;
      255: // count:word + data = copy (word) count RGB pixels of data
        begin
          Inc(id);
          Dec(len);

          wcnt := w^; // get count
          Inc(id, 2);
          Dec(len, 2);

          Assert((len >= wcnt * 3) and (longword(pixDest) - longword(pixOrig) + wcnt * 4 <= BlockSize));

          CopyDWord(id, pixDest, wcnt);

          Inc(id, wcnt * 3);
          Dec(len, wcnt * 3);

          Inc(pixDest, wcnt);
        end;
    else // count:byte (1..250) = skip count*4 bytes
      begin
        bcnt := b^;
        Inc(id);
        Dec(len);

        Assert((longword(pixDest) - longword(pixOrig) + bcnt * 4) <= BlockSize);

        Inc(pixDest, bcnt);
      end;
    end;
  end;
end;

end.
