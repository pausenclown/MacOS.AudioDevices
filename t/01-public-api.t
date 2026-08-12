use Test;
use lib 'lib';
use MacOS::AudioDevices;

my @required-methods =
    <audio-devices audio-input-devices audio-output-devices
     duplex-audio-devices active-input-device active-output-device
     set-output-device>;

for @required-methods -> $method {
    ok MacOS::AudioDevices.^can($method), "has method '$method'";
}

my @all = MacOS::AudioDevices.audio-devices();
ok @all ~~ Array, 'audio-devices returns Array';

my @input = MacOS::AudioDevices.audio-input-devices();
ok @input ~~ Array, 'audio-input-devices returns Array';

my @output = MacOS::AudioDevices.audio-output-devices();
ok @output ~~ Array, 'audio-output-devices returns Array';

if @all {
    ok @all[0]<id>:exists, 'device item contains id key';
    ok @all[0]<name>:exists, 'device item contains name key';
}

my $active-out = try { MacOS::AudioDevices.active-output-device() };

if $active-out.defined {
    ok $active-out<id>:exists, 'active output includes id';
    ok $active-out<name>:exists, 'active output includes name';
}
else {
    skip 'active output device unavailable in this environment', 2;
}

done-testing;
