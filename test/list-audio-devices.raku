use lib './lib';
use MacOS::AudioDevices;

say "ALL AUDIO DEVICES:";
.say for MacOS::AudioDevices.audio-devices();

say "INPUT AUDIO DEVICES:";
.say for MacOS::AudioDevices.audio-input-devices();

say "OUTPUT AUDIO DEVICES:";
.say for MacOS::AudioDevices.audio-output-devices();

say "ACTIVE INPUT AUDIO DEVICE:";
say MacOS::AudioDevices.active-input-device();

say "ACTIVE OUTPUT AUDIO DEVICE:";
say MacOS::AudioDevices.active-output-device();
