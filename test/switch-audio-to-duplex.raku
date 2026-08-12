use lib './lib';
use MacOS::AudioDevices;

MacOS::AudioDevices.set-output-device( 
    MacOS::AudioDevices.duplex-audio-devices().first.<id> 
);

say "NOW ACTIVE OUTPUT AUDIO DEVICE:";
say MacOS::AudioDevices.active-output-device();