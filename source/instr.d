module instr;
import std.stdio;
import expr;

struct Instrument {
  Atom expression;
  string name;
}

struct Strum {
  string name;
  int note, start, end;
}

class MusicMixer {
  Instrument[string] instruments;

  Strum[][int] strums;

  void New_Instrument ( Instrument i ) {
    instruments[i.name] = i;
  }

  void New_Strum ( string name, int note, int start, int end ) {
    for ( int i = start; i != end; ++ i ) {
      strums[i] ~= Strum(name, note, start, end);
    }
  }

  float Play_Note ( int idx, float time ) {
    if ( idx !in strums ) return 0.0f;
    float freq = 0.0f;
    foreach ( s; strums[idx] ) {
      float start = cast(float)s.start,
            end   = cast(float)s.end,
            fade   = 1.0f - (time-start)/(end-start);
      float res = instruments[s.name].expression.Eval(s.note, fade, time);
      freq += res;
    }
    return freq;
  }

  float Play_Note ( float time ) {
    int low = cast(int)(time), high = low+1;
    return (Play_Note(low, time));
  }
}
