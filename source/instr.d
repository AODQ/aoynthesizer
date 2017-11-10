module instr;
import std.stdio;
import expr;

struct Instrument {
  Atom expression;
  string name;
}

struct Strum {
  string name;
  float start, end;
  int note;
}

class MusicMixer {
  Atom freqadd;
  Instrument[string] instruments;

  Strum[][int] strums;
  float duration = 0.0f;

  void New_Instrument ( Instrument i ) {
    instruments[i.name] = i;
  }

  void New_Strum ( string name, int note, float start, float end ) {
    for ( int i = cast(int)start; i != cast(int)end+1; ++ i ) {
      strums[i] ~= Strum(name, start, end, note);
    }
    duration = duration < end ? end : duration;
  }

  float Play_Note ( int idx, float time ) {
    if ( idx !in strums ) return 0.0f;
    float freq = 0.0f;
    foreach ( s; strums[idx] ) {
      float start = s.start,
            end   = s.end;
      if ( time < start || time > end ) continue;
      float fade   = 1.0f - (time-start)/(end-start);
      float res = instruments[s.name].expression.Eval(s.note, fade,time,freq,0);
      freq = freqadd.Eval(s.note, fade, time, freq, res);
    }
    return freq;
  }

  float Play_Note ( float time ) {
    int low = cast(int)(time), high = low+1;
    return (Play_Note(low, time));
  }
}
