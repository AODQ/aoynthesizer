import std.stdio, std.math, std.algorithm, std.range, std.random;
import dlib.audio;
// A fun little synthesizer

auto New_sound ( float dur, uint freq ) {
  return new GenericSound(dur, freq, 2, SampleFormat.S16);
}

void main() {
  import interpreter;
  auto mm = Construct_Music();
  auto sound = New_sound(mm.duration, 1000);
  float time = 0.0f;
  float sample_period = 1.0f/cast(float)sound.sampleRate;
  foreach ( i; 0 .. sound.size ) {
    write(time, " ");
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
  { // vlc shell
    auto pid = spawnShell(`vlc -R test.mp3`);
    wait(pid);
  }
}
