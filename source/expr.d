module expr;
import std.stdio, std.variant;

struct Atom {
  Algebraic!(Atom[], float, string) v;

  this ( Atom[] list ) {v = list.dup; }
  this ( float val   ) {v = val;      }
  this ( string val  ) {v = val;      }

  float Eval(float note, float fade, float time) {
    import std.math;
    return v.visit!(
      (float f) { return f; },
      (Atom[] list) {
        if ( list.length == 1 )
          return list[0].Eval(note, fade, time);
        float lh = list[1].Eval(note, fade, time), rh, zh;
        if ( list.length > 2 )
          rh = list[2].Eval(note, fade, time);
        if ( list.length > 3 )
          zh = list[3].Eval(note, fade, time);
        switch(list[0].v.get!string) {
          default: assert(false, "Unknown function " ~ list[0].v.get!string);
          case "*": return lh * rh; case "/": return lh / rh;
          case "+": return lh + rh; case "-": return lh - rh;
          case "exp":
            return exp(lh);
          case "sine":
            return sin(6.2831f * lh);
          case "tsaw":
            // (saw) 0.0f <= q <= 0.5f (tri)
            float f = (lh - cast(int)(lh)) - rh;
            f /= (f >= 0.0f ? 1.0f : 0.0f) - rh;
            return f * 2.0f - 1.0f;
          case "env": // freq, attack, decay
            float env = (1.0f - exp(-lh * rh)) * exp(-lh * zh);
            float t_max = log((rh+zh)/zh)/rh;
            float env_max = (1.0f - exp(-t_max*rh))*exp(-t_max*zh);
            return env/env_max;
        }
      },
      (string s) {
        import std.random;
        switch ( s ) {
          default: assert(0, "VAR " ~ s ~ " UNDEFINED");
          case "R": return uniform(0.0f, 1.0f);
          case "N": return 16.35f * pow(1.059463f, note);
          case "F": return fade;
          case "T": return time;
        }
      }
    )();
  }
}
