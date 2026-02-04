program MidiPlayer;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults,
  Winapi.Windows,
  Winapi.MMSystem;

type
  TOutputMode = (omPianoRoll, omProgressBar);

  TMidiEvent = record
    DeltaMs: Integer;
    Status: Byte;
    Data1: Byte;
    Data2: Byte;
  end;

  TInternalEvent = record
    AbsoluteTime: Double;
    Status: Byte;
    Data1: Byte;
    Data2: Byte;
  end;

const
  // --- CONFIGURATION ---
  DisplayMode = omPianoRoll;
  PlaybackSpeed = 1.0;       // Increase to speed up (e.g., 1.1), decrease to slow down
  // ---------------------

  MIDI_NOTE_ON = $90;
  MIDI_CHANGE_INSTRUMENT = $C0;

  GM_INSTRUMENTS: array[0..127] of string = (
    'Acoustic Grand Piano', 'Bright Acoustic Piano', 'Electric Grand Piano', 'Honky-tonk Piano', 'Electric Piano 1', 'Electric Piano 2', 'Harpsichord', 'Clavi',
    'Celesta', 'Glockenspiel', 'Music Box', 'Vibraphone', 'Marimba', 'Xylophone', 'Tubular Bells', 'Dulcimer',
    'Drawbar Organ', 'Percussive Organ', 'Rock Organ', 'Church Organ', 'Reed Organ', 'Accordion', 'Harmonica', 'Tango Accordion',
    'Acoustic Guitar (nylon)', 'Acoustic Guitar (steel)', 'Electric Guitar (jazz)', 'Electric Guitar (clean)', 'Electric Guitar (muted)', 'Overdriven Guitar', 'Distortion Guitar', 'Guitar harmonics',
    'Acoustic Bass', 'Electric Bass (finger)', 'Electric Bass (pick)', 'Fretless Bass', 'Slap Bass 1', 'Slap Bass 2', 'Synth Bass 1', 'Synth Bass 2',
    'Violin', 'Viola', 'Cello', 'Contrabass', 'Tremolo Strings', 'Pizzicato Strings', 'Orchestral Harp', 'Timpani',
    'String Ensemble 1', 'String Ensemble 2', 'SynthStrings 1', 'SynthStrings 2', 'Choir Aahs', 'Voice Oohs', 'Synth Voice', 'Orchestra Hit',
    'Trumpet', 'Trombone', 'Tuba', 'Muted Trumpet', 'French Horn', 'Brass Section', 'SynthBrass 1', 'SynthBrass 2',
    'Soprano Sax', 'Alto Sax', 'Tenor Sax', 'Baritone Sax', 'Oboe', 'English Horn', 'Bassoon', 'Clarinet',
    'Piccolo', 'Flute', 'Recorder', 'Pan Flute', 'Blown Bottle', 'Shakuhachi', 'Whistle', 'Ocarina',
    'Lead 1 (square)', 'Lead 2 (sawtooth)', 'Lead 3 (calliope)', 'Lead 4 (chiff)', 'Lead 5 (charang)', 'Lead 6 (voice)', 'Lead 7 (fifths)', 'Lead 8 (bass + lead)',
    'Pad 1 (new age)', 'Pad 2 (warm)', 'Pad 3 (polysynth)', 'Pad 4 (choir)', 'Pad 5 (bowed)', 'Pad 6 (metallic)', 'Pad 7 (halo)', 'Pad 8 (sweep)',
    'FX 1 (rain)', 'FX 2 (soundtrack)', 'FX 3 (crystal)', 'FX 4 (atmosphere)', 'FX 5 (brightness)', 'FX 6 (goblins)', 'FX 7 (echoes)', 'FX 8 (sci-fi)',
    'Sitar', 'Banjo', 'Shamisen', 'Koto', 'Kalimba', 'Bag pipe', 'Fiddle', 'Shanai',
    'Tinkle Bell', 'Agogo', 'Steel Drums', 'Woodblock', 'Taiko Drum', 'Melodic Tom', 'Synth Drum', 'Reverse Cymbal',
    'Guitar Fret Noise', 'Breath Noise', 'Seashore', 'Bird Tweet', 'Telephone Ring', 'Helicopter', 'Applause', 'Gunshot'
  );

var
  hMidi: HMIDIOUT;
  MasterPlaylist: TList<TMidiEvent>;
  CurrentTempo: Cardinal = 500000;
  Division: Word;
  TotalDurationMs: Int64 = 0;

function ReadBEWord(Stream: TStream): Word;
var B: array[0..1] of Byte;
begin
  if Stream.Position + 2 > Stream.Size then exit(0);
  Stream.ReadBuffer(B, 2);
  Result := (B[0] shl 8) or B[1];
end;

function ReadBECardinal(Stream: TStream): Cardinal;
var B: array[0..3] of Byte;
begin
  if Stream.Position + 4 > Stream.Size then exit(0);
  Stream.ReadBuffer(B, 4);
  Result := (B[0] shl 24) or (B[1] shl 16) or (B[2] shl 8) or B[3];
end;

function ReadVLQ(Stream: TStream): Cardinal;
var B: Byte;
begin
  Result := 0;
  repeat
    if Stream.Position >= Stream.Size then Break;
    Stream.ReadBuffer(B, 1);
    Result := (Result shl 7) or (B and $7F);
  until (B and $80) = 0;
end;

procedure LoadMidi(const FileName: string);
var
  MidiFile: TFileStream;
  ID: array[0..3] of AnsiChar;
  HeaderLen, TrackLen, TrackEnd: Cardinal;
  NumTracks, TrackIdx: Integer;
  Delta: Cardinal;
  Status, LastStatus, Data1, Data2: Byte;
  MetaType, MetaLen: Cardinal;
  TicksToMs, GlobalTimeMs, PrevTimeMs: Double;
  T: array[0..2] of Byte;
  TempList: TList<TInternalEvent>;
  InternalEv: TInternalEvent;
  FinalEv: TMidiEvent;
  I: Integer;
begin
  if not FileExists(FileName) then Exit;
  MidiFile := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  TempList := TList<TInternalEvent>.Create;
  try
    MidiFile.ReadBuffer(ID, 4);
    HeaderLen := ReadBECardinal(MidiFile);
    MidiFile.Seek(2, soFromCurrent);
    NumTracks := ReadBEWord(MidiFile);
    Division := ReadBEWord(MidiFile);
    if HeaderLen > 6 then MidiFile.Seek(HeaderLen - 6, soFromCurrent);

    for TrackIdx := 0 to NumTracks - 1 do
    begin
      if MidiFile.Position + 8 > MidiFile.Size then Break;
      MidiFile.ReadBuffer(ID, 4);
      TrackLen := ReadBECardinal(MidiFile);
      TrackEnd := MidiFile.Position + TrackLen;
      TicksToMs := CurrentTempo / (Division * 1000.0);
      GlobalTimeMs := 0;
      LastStatus := 0;

      while MidiFile.Position < TrackEnd do
      begin
        Delta := ReadVLQ(MidiFile);
        GlobalTimeMs := GlobalTimeMs + (Delta * TicksToMs);
        if MidiFile.Position >= MidiFile.Size then Break;
        MidiFile.ReadBuffer(Status, 1);

        Data1 := 0; Data2 := 0;
        if (Status and $80) = 0 then begin Data1 := Status; Status := LastStatus; end
        else begin
          if Status < $F0 then LastStatus := Status;
          if Status < $F0 then if MidiFile.Position < MidiFile.Size then MidiFile.ReadBuffer(Data1, 1);
        end;

        case Status and $F0 of
          $80, $90, $A0, $B0, $E0: begin
            if MidiFile.Position < MidiFile.Size then MidiFile.ReadBuffer(Data2, 1);
            InternalEv.AbsoluteTime := GlobalTimeMs; InternalEv.Status := Status;
            InternalEv.Data1 := Data1; InternalEv.Data2 := Data2;
            TempList.Add(InternalEv);
          end;
          $C0, $D0: begin
            InternalEv.AbsoluteTime := GlobalTimeMs; InternalEv.Status := Status;
            InternalEv.Data1 := Data1; InternalEv.Data2 := 0;
            TempList.Add(InternalEv);
          end;
          $F0: if Status = $FF then begin
              if MidiFile.Position < MidiFile.Size then MidiFile.ReadBuffer(MetaType, 1);
              MetaLen := ReadVLQ(MidiFile);
              if (MetaType = $51) and (MidiFile.Position + 3 <= MidiFile.Size) then begin
                MidiFile.ReadBuffer(T[0], 1); MidiFile.ReadBuffer(T[1], 1); MidiFile.ReadBuffer(T[2], 1);
                CurrentTempo := (T[0] shl 16) or (T[1] shl 8) or T[2];
                TicksToMs := CurrentTempo / (Division * 1000.0);
              end else MidiFile.Seek(Min(MetaLen, Cardinal(MidiFile.Size - MidiFile.Position)), soFromCurrent);
            end else begin MetaLen := ReadVLQ(MidiFile); MidiFile.Seek(Min(MetaLen, Cardinal(MidiFile.Size - MidiFile.Position)), soFromCurrent); end;
        end;
      end;
      MidiFile.Position := TrackEnd;
    end;

    TempList.Sort(TComparer<TInternalEvent>.Construct(function(const L, R: TInternalEvent): Integer
      begin Result := CompareValue(L.AbsoluteTime, R.AbsoluteTime); end));

    PrevTimeMs := 0;
    TotalDurationMs := 0;
    for I := 0 to TempList.Count - 1 do
    begin
      FinalEv.DeltaMs := Round(Max(0, TempList[I].AbsoluteTime - PrevTimeMs));
      FinalEv.Status := TempList[I].Status;
      FinalEv.Data1 := TempList[I].Data1;
      FinalEv.Data2 := TempList[I].Data2;
      MasterPlaylist.Add(FinalEv);
      TotalDurationMs := TotalDurationMs + FinalEv.DeltaMs;
      PrevTimeMs := TempList[I].AbsoluteTime;
    end;
  finally
    TempList.Free;
    MidiFile.Free;
  end;
end;

procedure SetConsoleColor(Color: Word);
var hOut: THandle;
begin
  hOut := GetStdHandle(STD_OUTPUT_HANDLE);
  SetConsoleTextAttribute(hOut, Color);
end;

procedure DrawPianoRoll(Note, Channel, Velocity: Byte; IsOn: Boolean);
var
  Pos: Integer;
  BarChar: string;
  Padding: string;
  Color: Word;
begin
  Pos := Round((Note / 127) * 40);
  Padding := StringOfChar(' ', Pos);
  if Velocity > 100 then BarChar := '█' else if Velocity > 60 then BarChar := '▓' else if Velocity > 30 then BarChar := '▒' else BarChar := '░';
  case Channel of
    9: Color := FOREGROUND_RED or FOREGROUND_INTENSITY;
    0..2: Color := FOREGROUND_GREEN or FOREGROUND_INTENSITY;
    3..5: Color := FOREGROUND_BLUE or FOREGROUND_INTENSITY;
    else Color := FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  end;
  SetConsoleColor(Color);
  if IsOn then Writeln(Format('[Ch %2d] %s%s (Note:%3d Vel:%3d)', [Channel, Padding, BarChar, Note, Velocity]))
  else Writeln(Format('[Ch %2d] %s· OFF', [Channel, Padding]));
  SetConsoleColor(FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE);
end;

procedure DrawProgressBar(CurrentTimeMs: Int64);
var
  Percent: Double;
  BarWidth, FillWidth: Integer;
  S: string;
begin
  if TotalDurationMs = 0 then Percent := 100 else Percent := (CurrentTimeMs / TotalDurationMs) * 100;
  BarWidth := 40;
  FillWidth := Round((Percent / 100) * BarWidth);

  S := Format(#13' [%s%s] %3.1f%% | %d:%02d / %d:%02d ', [
    StringOfChar('█', FillWidth),
    StringOfChar('-', BarWidth - FillWidth),
    Percent,
    (CurrentTimeMs div 1000) div 60, (CurrentTimeMs div 1000) mod 60,
    (TotalDurationMs div 1000) div 60, (TotalDurationMs div 1000) mod 60
  ]);
  Write(S);
end;

procedure PlayMidi;
var
  I: Integer;
  Msg: DWORD;
  Channel, Note, Velocity, EventType: Byte;
  ElapsedTimeMs: Int64;
  WaitMs: Integer;
begin
  if midiOutOpen(@hMidi, MIDIMAPPER, 0, 0, CALLBACK_NULL) <> MMSYSERR_NOERROR then Exit;

  // CRITICAL: Request 1ms timer precision from Windows
  timeBeginPeriod(1);

  try
    Writeln('Playback started (Speed: ', PlaybackSpeed:1:2, 'x)...');
    Writeln('----------------------------------------');

    ElapsedTimeMs := 0;
    for I := 0 to MasterPlaylist.Count - 1 do
    begin
      WaitMs := MasterPlaylist[I].DeltaMs;

      if WaitMs > 0 then
      begin
        // Apply speed multiplier and sleep
        Sleep(Round(WaitMs / PlaybackSpeed));
        ElapsedTimeMs := ElapsedTimeMs + WaitMs;
      end;

      Msg := MasterPlaylist[I].Status or (MasterPlaylist[I].Data1 shl 8) or (MasterPlaylist[I].Data2 shl 16);
      midiOutShortMsg(hMidi, Msg);

      Channel := MasterPlaylist[I].Status and $0F;
      EventType := MasterPlaylist[I].Status and $F0;
      Note := MasterPlaylist[I].Data1;
      Velocity := MasterPlaylist[I].Data2;

      case DisplayMode of
        omPianoRoll:
          begin
            if (EventType = $90) and (Velocity > 0) then DrawPianoRoll(Note, Channel, Velocity, True)
            else if (EventType = $80) or ((EventType = $90) and (Velocity = 0)) then DrawPianoRoll(Note, Channel, Velocity, False)
            else if (EventType = $C0) then
            begin
              SetConsoleColor(FOREGROUND_RED or FOREGROUND_BLUE or FOREGROUND_INTENSITY);
              Writeln(Format('[Ch %2d] INSTRUMENT CHANGE: %s', [Channel, GM_INSTRUMENTS[Note]]));
              SetConsoleColor(FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE);
            end;
          end;
        omProgressBar: DrawProgressBar(ElapsedTimeMs);
      end;
    end;
  finally
    timeEndPeriod(1); // Release timer precision
    if DisplayMode = omProgressBar then Writeln;
    Writeln('----------------------------------------');
    Writeln('Playback complete.');
    midiOutReset(hMidi);
    midiOutClose(hMidi);
  end;
end;

begin
  if (ParamCount < 1) or not FileExists(ParamStr(1)) then
  begin
    Writeln('Aperture MIDI Player (Visual Edition)');
    Writeln('Usage: MidiPlayer.exe <filename.mid>');
    Writeln;
    Write('Press Enter to exit...'); Readln;
    Exit;
  end;

  MasterPlaylist := TList<TMidiEvent>.Create;
  try
    Writeln('Loading: ' + ExtractFileName(ParamStr(1)));
    LoadMidi(ParamStr(1));
    PlayMidi;
  finally MasterPlaylist.Free; end;
end.
