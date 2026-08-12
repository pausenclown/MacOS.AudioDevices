use lib './lib';
use MacOS::AudioDevices;

MacOS::AudioDevices.set-output-device( "BlackHole 2ch" );

say "NOW ACTIVE OUTPUT AUDIO DEVICE:";
say MacOS::AudioDevices.active-output-device();
