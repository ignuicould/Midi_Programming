program MidiExtractor;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.Math, System.StrUtils,
  System.Generics.Collections, System.Generics.Defaults;

type
  TMidiEvent = record
    DeltaMs: Integer;
    MidiNote: Byte;
    Velocity: Byte;
    Channel: Byte;
  end;

  TRawEvent = record
    AbsoluteTime: Double;
    MidiNote: Byte;
    Velocity: Byte;
    Channel: Byte;
  end;

  // Added missing type definition to fix E2003
  TSetOfByte = set of Byte;

const
  // General MIDI Instrument Names
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
  MidiFile: TFileStream;
  RawEvents: TList<TRawEvent>;
  ChannelInstruments: array[0..15] of Byte;
  ChannelNoteCounts: array[0..15] of Integer;
  Division: Word;
  CurrentTempo: Cardinal = 500000;
  GlobalTimeMs: Double = 0;

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

procedure ProcessMidi(const FileName: string);
var
  ID: array[0..3] of AnsiChar;
  HeaderLen, TrackLen, TrackEnd: Cardinal;
  FormatType, NumTracks: Word;
  TrackIdx: Integer;
  Delta: Cardinal;
  Status, LastStatus, EventType: Byte;
  Data1, Data2: Byte;
  MetaType, MetaLen: Cardinal;
  TicksToMs: Double;
  T1, T2, T3: Byte;
  Event: TRawEvent;
begin
  if not FileExists(FileName) then Exit;
  MidiFile := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    MidiFile.ReadBuffer(ID, 4);
    HeaderLen := ReadBECardinal(MidiFile);
    FormatType := ReadBEWord(MidiFile);
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
        if (Status and $80) = 0 then begin Data1 := Status; Status := LastStatus; end
        else begin if MidiFile.Position < MidiFile.Size then MidiFile.ReadBuffer(Data1, 1); if Status < $F0 then LastStatus := Status; end;

        EventType := Status and $F0;
        case EventType of
          $80, $90: begin
            if MidiFile.Position < MidiFile.Size then MidiFile.ReadBuffer(Data2, 1);
            Event.AbsoluteTime := GlobalTimeMs;
            Event.MidiNote := Data1;
            Event.Channel := Status and $0F;
            if EventType = $80 then Event.Velocity := 0 else Event.Velocity := Data2;
            RawEvents.Add(Event);
            if Event.Velocity > 0 then Inc(ChannelNoteCounts[Event.Channel]);
          end;
          $C0: ChannelInstruments[Status and $0F] := Data1;
          $A0, $B0, $E0: if MidiFile.Position < MidiFile.Size then MidiFile.ReadBuffer(Data2, 1);
          $F0: begin
            if Status = $FF then begin
              if MidiFile.Position < MidiFile.Size then MidiFile.ReadBuffer(MetaType, 1);
              MetaLen := ReadVLQ(MidiFile);
              if (MetaType = $51) and (MidiFile.Position + 3 <= MidiFile.Size) then begin
                MidiFile.ReadBuffer(T1, 1); MidiFile.ReadBuffer(T2, 1); MidiFile.ReadBuffer(T3, 1);
                CurrentTempo := (T1 shl 16) or (T2 shl 8) or T3;
                TicksToMs := CurrentTempo / (Division * 1000.0);
              end else MidiFile.Seek(Min(MetaLen, Cardinal(MidiFile.Size - MidiFile.Position)), soFromCurrent);
            end else begin MetaLen := ReadVLQ(MidiFile); MidiFile.Seek(Min(MetaLen, Cardinal(MidiFile.Size - MidiFile.Position)), soFromCurrent); end;
          end;
        end;
      end;
      MidiFile.Position := TrackEnd;
    end;
  finally MidiFile.Free; end;
end;

procedure OutputDelphiCode;
var
  I, ChoiceIdx: Integer;
  PrevTime: Double;
  ActiveChannels: TList<Byte>;
  FilteredEvents: TList<TRawEvent>;
  UserInput: string;
  Choices: TArray<string>;
  SelectedChannels: TSetOfByte;
begin
  if RawEvents.Count = 0 then Exit;

  ActiveChannels := TList<Byte>.Create;
  try
    Writeln('Select instrument(s) to extract (e.g., "1" or "1,2,5"):');
    Writeln('------------------------------------------------------');
    for I := 0 to 15 do
    begin
      if ChannelNoteCounts[I] > 0 then
      begin
        ActiveChannels.Add(I);
        Writeln(Format('[%d] Channel %d: %s (%d notes)',
          [ActiveChannels.Count, I, GM_INSTRUMENTS[ChannelInstruments[I]], ChannelNoteCounts[I]]));
      end;
    end;

    if ActiveChannels.Count = 0 then
    begin
      Writeln('No playable channels found.');
      Exit;
    end;

    Write('Enter selection(s): ');
    Readln(UserInput);

    // Parse comma-delimited input
    Choices := UserInput.Split([',', ' '], TStringSplitOptions.ExcludeEmpty);
    SelectedChannels := [];

    for I := 0 to High(Choices) do
    begin
      if TryStrToInt(Trim(Choices[I]), ChoiceIdx) then
      begin
        if (ChoiceIdx >= 1) and (ChoiceIdx <= ActiveChannels.Count) then
          Include(SelectedChannels, ActiveChannels[ChoiceIdx - 1]);
      end;
    end;

    if SelectedChannels = [] then
    begin
      Writeln('No valid selections made.');
      Exit;
    end;

    FilteredEvents := TList<TRawEvent>.Create;
    try
      for I := 0 to RawEvents.Count - 1 do
      begin
        if RawEvents[I].Channel in SelectedChannels then
          FilteredEvents.Add(RawEvents[I]);
      end;

      // Re-sort to ensure mixed channels are in temporal order
      FilteredEvents.Sort(TComparer<TRawEvent>.Construct(function(const L, R: TRawEvent): Integer
        begin Result := CompareValue(L.AbsoluteTime, R.AbsoluteTime); end));

      Writeln;
      Writeln('// Combined Channels: ', UserInput);
      Writeln('  MELODY: array[0..', FilteredEvents.Count - 1, '] of TMidiEvent = (');
      PrevTime := 0;
      for I := 0 to FilteredEvents.Count - 1 do
      begin
        Write(Format('    (DeltaMs: %d; MidiNote: %d; Velocity: %d; Channel: %d)',
          [Round(Max(0, FilteredEvents[I].AbsoluteTime - PrevTime)),
           FilteredEvents[I].MidiNote, FilteredEvents[I].Velocity, FilteredEvents[I].Channel]));

        if I < FilteredEvents.Count - 1 then
        begin
          if (I + 1) mod 2 = 0 then Writeln(',') else Write(', ');
        end;
        PrevTime := FilteredEvents[I].AbsoluteTime;
      end;
      Writeln;
      Writeln('  );');
    finally
      FilteredEvents.Free;
    end;
  finally
    ActiveChannels.Free;
  end;
end;

begin
  RawEvents := TList<TRawEvent>.Create;
  FillChar(ChannelInstruments, SizeOf(ChannelInstruments), 0);
  FillChar(ChannelNoteCounts, SizeOf(ChannelNoteCounts), 0);
  try
    ProcessMidi(IfThen(ParamCount > 0, ParamStr(1), 'default.mid'));
    OutputDelphiCode;
  finally RawEvents.Free; end;
  Writeln; Write('Press Enter to exit...'); Readln;
end.
