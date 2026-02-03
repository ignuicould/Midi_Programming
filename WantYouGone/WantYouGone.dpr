program WantYouGone;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Diagnostics, // Used for precise lyric timing
  Winapi.Windows,
  Winapi.MMSystem;

type
  TMidiEvent = record
    DeltaMs: Integer;
    MidiNote: Byte;
    Velocity: Byte;
    Channel: Byte;
  end;

  // Karaoke structure using absolute timing for precision
  TKaraokeLine = record
    TimeMs: Integer;
    Lyric: string;
  end;

const
  MIDI_NOTE_ON = $90;
  MIDI_NOTE_OFF = $80;
  MIDI_CHANGE_INSTRUMENT = $C0;

  PRIMARY_CHANNEL = 7;
  BACKGROUND_SCALER = 0.9; //90% volume

  // Example Melody
  MELODY: array[0..651] of TMidiEvent = (
    (DeltaMs: 0; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 51; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 51; Velocity: 0; Channel: 0),     (DeltaMs: 505; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 50; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 50; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 50; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 50; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 53; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 53; Velocity: 0; Channel: 0),     (DeltaMs: 505; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 51; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 51; Velocity: 0; Channel: 0),     (DeltaMs: 505; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 50; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 50; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 50; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 50; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 45; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 45; Velocity: 0; Channel: 0),     (DeltaMs: 5; MidiNote: 53; Velocity: 100; Channel: 0),
    (DeltaMs: 245; MidiNote: 53; Velocity: 0; Channel: 0),     (DeltaMs: 505; MidiNote: 45; Velocity: 0; Channel: 0),
    //MAIN PIANO
    (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 693; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 130; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 755; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 130; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 255; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 1255; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 68; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 57; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 630; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 380; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 65; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 65; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 745; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 505; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 70; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 70; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 68; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 745; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 1005; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 54; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 54; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 54; Velocity: 100; Channel: 7),     (DeltaMs: 1745; MidiNote: 54; Velocity: 0; Channel: 7),
    (DeltaMs: 1005; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 70; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 70; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 68; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 65; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 65; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 370; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 1245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 2880; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 755; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 130; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 380; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 130; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 255; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 370; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 1130; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 68; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 57; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 630; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 370; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 380; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 130; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 65; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 65; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 745; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 505; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 70; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 70; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 68; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 745; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 1005; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 63; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 63; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 61; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 54; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 58; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 54; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 63; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 63; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 61; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 54; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 58; Velocity: 100; Channel: 7),
    (DeltaMs: 1745; MidiNote: 58; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 54; Velocity: 0; Channel: 7),
    (DeltaMs: 1005; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 70; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 70; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 68; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 370; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 1245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 2755; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 630; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 318; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 130; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 380; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 318; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 120; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 68; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 255; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 1255; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 630; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 182; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 56; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 56; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 620; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 52; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 52; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 65; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 65; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 745; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 505; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 70; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 70; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 68; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 745; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 1005; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 63; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 63; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 61; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 54; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 58; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 54; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 63; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 63; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 61; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 54; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 58; Velocity: 100; Channel: 7),
    (DeltaMs: 1745; MidiNote: 58; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 54; Velocity: 0; Channel: 7),
    (DeltaMs: 1005; MidiNote: 58; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 58; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 70; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 70; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 68; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 495; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 68; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 64; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 100; Channel: 7),
    (DeltaMs: 495; MidiNote: 68; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 100; Channel: 7),
    (DeltaMs: 370; MidiNote: 64; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 62; Velocity: 100; Channel: 7),
    (DeltaMs: 120; MidiNote: 62; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 61; Velocity: 100; Channel: 7),
    (DeltaMs: 1245; MidiNote: 61; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 255; MidiNote: 68; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 64; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 100; Channel: 7),
    (DeltaMs: 495; MidiNote: 68; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 100; Channel: 7),
    (DeltaMs: 370; MidiNote: 64; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 61; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 59; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 62; Velocity: 100; Channel: 7),
    (DeltaMs: 120; MidiNote: 62; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 59; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 61; Velocity: 100; Channel: 7),
    (DeltaMs: 1245; MidiNote: 61; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 57; Velocity: 0; Channel: 7),
    (DeltaMs: 255; MidiNote: 65; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 65; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 66; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 69; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 69; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 64; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 68; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 68; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 255; MidiNote: 62; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 66; Velocity: 100; Channel: 7),
    (DeltaMs: 245; MidiNote: 66; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 62; Velocity: 0; Channel: 7),
    (DeltaMs: 5; MidiNote: 61; Velocity: 100; Channel: 7),     (DeltaMs: 0; MidiNote: 64; Velocity: 100; Channel: 7),
    (DeltaMs: 0; MidiNote: 57; Velocity: 100; Channel: 7),     (DeltaMs: 2745; MidiNote: 64; Velocity: 0; Channel: 7),
    (DeltaMs: 0; MidiNote: 61; Velocity: 0; Channel: 7),     (DeltaMs: 0; MidiNote: 57; Velocity: 0; Channel: 7)
  );

  LYRICS: array[0..30] of TKaraokeLine = (
    // --- VERSE 1 (Starts at Zero + 8s Offset) ---
    (TimeMs: 8000;   Lyric: 'Well here we are again'),
    (TimeMs: 10000;  Lyric: 'It''s always such a pleasure'),
    (TimeMs: 12500;  Lyric: 'Remember when you tried to kill me twice?'),
    (TimeMs: 16500;  Lyric: 'Oh how we laughed and laughed'),
    (TimeMs: 18500;  Lyric: 'Except I wasn''t laughing'),
    (TimeMs: 20500;  Lyric: 'Under the circumstances I''ve been shockingly nice'),

    // --- CHORUS 1 ---
    (TimeMs: 25500;  Lyric: 'You want your freedom? Take it'),
    (TimeMs: 29500;  Lyric: 'That''s what I''m counting on'),
    (TimeMs: 33500;  Lyric: 'I used to want you dead but now I only want you gone'),
    (TimeMs: 40000;  Lyric: '...'),

    // --- VERSE 2 ---
    (TimeMs: 42000;  Lyric: 'She was a lot like you'),
    (TimeMs: 45000;  Lyric: '(Maybe not quite as heavy)'),
    (TimeMs: 47500;  Lyric: 'Now little Caroline is in here too'),
    (TimeMs: 51500;  Lyric: 'One day they woke me up'),
    (TimeMs: 53500;  Lyric: 'So I could live forever'),
    (TimeMs: 56000;  Lyric: 'It''s such a shame the same will never happen to you'),

    // --- CHORUS 2 ---
    (TimeMs: 60500;  Lyric: 'You''ve got your short sad life left'),
    (TimeMs: 65000;  Lyric: 'That''s what I''m counting on'),
    (TimeMs: 68500;  Lyric: 'I''ll let you get right to it, now I only want you gone'),
    (TimeMs: 76000;  Lyric: '...'),

    // --- BRIDGE / OUTRO ---
    (TimeMs: 78500;  Lyric: 'Goodbye my only friend'),
    (TimeMs: 80500;  Lyric: 'Oh, did you think I meant you?'),
    (TimeMs: 82500;  Lyric: 'That would be funny if it weren''t so sad'),
    (TimeMs: 86000;  Lyric: 'Well you have been replaced'),
    (TimeMs: 89000;  Lyric: 'I don''t need anyone now'),
    (TimeMs: 91000;  Lyric: 'When I delete you maybe'),
    (TimeMs: 92500;  Lyric: '[REDACTED]'),
    (TimeMs: 96000;  Lyric: 'Go make some new disaster'),
    (TimeMs: 99000;  Lyric: 'That''s what I''m counting on'),
    (TimeMs: 104000;  Lyric: 'You''re someone else''s problem'),
    (TimeMs: 107000;  Lyric: 'Now I only want you gone')
  );

var
  hMidi: HMIDIOUT;
  i, LyricIdx: Integer;
  MidiMsg: DWORD;
  StatusByte: Byte;
  FinalVelocity: Byte;
  Stopwatch: TStopwatch;
  ElapsedMs: Int64;

begin
  try
    Writeln('Forms FORM-29827281-12-2:');

    if midiOutOpen(@hMidi, MIDIMAPPER, 0, 0, CALLBACK_NULL) <> MMSYSERR_NOERROR then
    begin
      Writeln('Error: Could not open MIDI Mapper.');
      Exit;
    end;

    // Set Instruments
    midiOutShortMsg(hMidi, MIDI_CHANGE_INSTRUMENT or PRIMARY_CHANNEL or (88 shl 8));
    midiOutShortMsg(hMidi, MIDI_CHANGE_INSTRUMENT or (88 shl 8));

    Writeln('Notice of Dismissal');
    Writeln;

    LyricIdx := Low(LYRICS);
    Stopwatch := TStopwatch.StartNew;

    for i := Low(MELODY) to High(MELODY) do
    begin
      // 1. Sync and Wait for the next MIDI event
      if MELODY[i].DeltaMs > 0 then
      begin
        // Before sleeping, check if any lyrics need to trigger DURING the delta wait
        while (LyricIdx <= High(LYRICS)) and
              (Stopwatch.ElapsedMilliseconds >= LYRICS[LyricIdx].TimeMs) do
        begin
          Writeln(' ' + LYRICS[LyricIdx].Lyric);
          Inc(LyricIdx);
        end;

        Sleep(MELODY[i].DeltaMs);
      end;

      // 2. Post-sleep lyric check
      while (LyricIdx <= High(LYRICS)) and
            (Stopwatch.ElapsedMilliseconds >= LYRICS[LyricIdx].TimeMs) do
      begin
        Writeln(' ' + LYRICS[LyricIdx].Lyric);
        Inc(LyricIdx);
      end;

      // 3. Process MIDI Message
      if MELODY[i].Velocity > 0 then
        StatusByte := MIDI_NOTE_ON or (MELODY[i].Channel and $0F)
      else
        StatusByte := MIDI_NOTE_OFF or (MELODY[i].Channel and $0F);

      FinalVelocity := MELODY[i].Velocity;
      if (MELODY[i].Channel <> PRIMARY_CHANNEL) and (FinalVelocity > 0) then
      begin
        FinalVelocity := Round(FinalVelocity * BACKGROUND_SCALER);
        if FinalVelocity < 10 then FinalVelocity := 10;
      end;

      MidiMsg := StatusByte or (MELODY[i].MidiNote shl 8) or (FinalVelocity shl 16);
      midiOutShortMsg(hMidi, MidiMsg);
    end;

    Writeln;
    Writeln('End of program.');
    midiOutReset(hMidi);
    midiOutClose(hMidi);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
