use lib './lib';
use MacOS::AudioDevices;

my %speaker =
    MacOS::AudioDevices.audio-output-devices().first({
        .<name> ~~ m:i/speaker/
    });

die "No output device matching /speaker/i was found"
    unless %speaker;

MacOS::AudioDevices.set-output-device(%speaker<id>);

say "NOW ACTIVE OUTPUT AUDIO DEVICE:";
say MacOS::AudioDevices.active-output-device();

