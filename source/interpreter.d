module interpreter;
import std.stdio, std.conv, std.algorithm, std.string;
static import std.file;
import instr;
import pegged.grammar;

// Grammar loosely adapted from my prototype signed distance fields generator
// based on scheme, AODHeme. Of course, without lambdas, lists, etc this becomes
// nearly trivial.
mixin(grammar(`
AG:
  Mixer < Instrument Music
  Instrument < '%' InstrumentT+ '%'
  InstrumentT < Iden Struct

  Music < '%' MusicT+ '%'
  MusicT < 'T' Unsigned Strum+
  Strum < Iden '!' Note '(' Unsigned ')'

  SExpr < "(" (Atom/SExpr)+ ")"

  Sign <- "-"
  Unsigned <- digit+
  FloatL   <- Integer "." Unsigned "f"
  Integer  <- Sign? Unsigned

  Atom <- FloatL / Integer / Iden / Operator

  Iden <- identifier
  Operator <- ("+" / "-" / "*" / "/" / "^" / "<")


  Struct   < '{' StructL '}'
  StructL  < SExpr (',' SExpr)*

  Func     < Iden '!' SExpr
  Note     < [A-Z]
`));

import expr;
Atom Parse_Atom ( ParseTree p ) {
  switch ( p.name ) {
    default: assert(false, "Unknown " ~ p.name);
    case "AG.SExpr":
      Atom[] atoms;
      foreach ( c; p.children )
        atoms ~= Parse_Atom(c);
      return Atom(atoms);
    case "AG.Iden":
      return Atom(p.input[p.begin..p.end]);
    case "AG.Atom":
      return Parse_Atom(p.children[0]);
    case "AG.Operator": return Atom(p.matches[0]);
    case "AG.FloatL":   return Atom(p.input[p.begin..p.end-1].to!float);
    case "AG.Integer":  return Atom(p.input.to!int);
  }
}

Instrument Parse_Instrument ( ParseTree p ) {
  assert(p.name == "AG.InstrumentT");
  string name = p.children[0].matches[0];
  ParseTree exp = p.children[1].children[0].children[0];
  assert(exp.name == "AG.SExpr");
  return Instrument(Parse_Atom(exp), name);
}

void Parse_Strum ( ParseTree p, ref MusicMixer mm ) {
  assert(p.name == "AG.MusicT");
  int note_start = p.children[0].matches[0].to!int;
  foreach ( strum; p.children[1..$] ) {
    assert(strum.name == "AG.Strum");
    string label = strum.children[0].matches[0];
    int note = cast(int)(strum.children[1].matches[0][0]);
    int note_end = note_start + strum.children[2].matches.join().to!int;
    mm.New_Strum(label, note, note_start, note_end);
  }
}

void Parse_Code ( ParseTree ptree, ref MusicMixer mm ) {
  foreach ( p; ptree.children ) {
    switch ( p.name ) {
      default: assert(false, "UNKNOWN START " ~ p.name);
      case "AG.Mixer":
        foreach ( i; p.children )
          Parse_Code(i, mm);
      break;
      case "AG.InstrumentT":
        mm.New_Instrument(Parse_Instrument(p));
      break;
      case "AG.MusicT":
        Parse_Strum(p, mm);
      break;
    }
  }
}

MusicMixer Construct_Music () {
  string dstr;
  File aofile = File("aoynthesizer.mu");
  foreach (line; aofile.byLine(KeepTerminator.no)) { // comment hack
    if ( line.length > 0 && line[0] == '#' ) continue;
    dstr ~= line ~ ' ';
  }
  auto ag = AG(dstr);
  writeln("`%s`".format(dstr));

  {
    import pegged.tohtml;
    toHTML(ag, "parser.html");
  }

  MusicMixer mm = new MusicMixer();
  Parse_Code(ag, mm);
  return mm;
}