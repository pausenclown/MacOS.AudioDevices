use lib './lib';
use MacOS::AudioDevices;

my $id = MacOS::AudioDevices.duplex-audio-devices().first.<id>;

MacOS::AudioDevices.set-output-device( $id );
say "NOW ACTIVE OUTPUT AUDIO DEVICE:";
say MacOS::AudioDevices.active-output-device();


MacOS::AudioDevices.set-input-device( $id );
say "NOW ACTIVE INPUT AUDIO DEVICE:";
say MacOS::AudioDevices.active-input-device();