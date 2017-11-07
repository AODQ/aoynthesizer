import std.stdio, std.math, std.algorithm, std.range, std.random;
import dlib.audio;
// A fun little synthesizer

auto New_sound ( float dur, uint freq ) {
  return new GenericSound(dur, freq, 2, SampleFormat.S16);
}

float Strum(float time, float freq, float function(float, float) f, float tint,
            int[] values) {
  float b = 0.0f;
  float t = time/tint,
        x = 0.0f;
  foreach ( v; values ) {
    b += cast(float)(v);
    if ( t > b )
      x = b;
  }
  return f(freq, tint*(t - x));
}

void D(ref float b, ref float x, ref float t, int[] values) {
  x = t;
  b = 0.0f;
  foreach ( v; values ) {
    b += cast(float)(v);
    if ( t > b ) x = b;
  }
}

void main() {
  import interpreter;
  auto mm = Construct_Music();
  auto sound = New_sound(10.0, 1000);
  float time = 0.0f;
  float sample_period = 1.0f/cast(float)sound.sampleRate;
  foreach ( i; 0 .. sound.size ) {
    sound[0, i] = sound[1, i] = mm.Play_Note(time);
    time += sample_period;
  }
  saveWAV(sound, "test.wav");
  import std.process;
  { // lame -V2 test.wav test.mp3
    auto pid = spawnShell(`lame -V2 test.wav test.mp3`);
    wait(pid);
  }
  { // delete
    auto pid = spawnShell(`rm test.wav`);
    wait(pid);
  }
  { // delete
    auto pid = spawnShell(`vlc -R test.mp3`);
    wait(pid);
  }
}
