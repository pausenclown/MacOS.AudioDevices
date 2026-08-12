unit class MacOS::AudioDevices;

use NativeCall;

constant CORE_AUDIO =
    '/System/Library/Frameworks/CoreAudio.framework/CoreAudio';

constant CORE_FOUNDATION =
    '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation';

# --------------------------------------------------------------------------
# Types
# --------------------------------------------------------------------------

class AudioObjectPropertyAddress is repr('CStruct') {
    has uint32 $.mSelector;
    has uint32 $.mScope;
    has uint32 $.mElement;
}

# --------------------------------------------------------------------------
# Native functions
# --------------------------------------------------------------------------

sub AudioObjectGetPropertyDataSize(
    uint32,
    AudioObjectPropertyAddress,
    uint32,
    Pointer,
    uint32 is rw
    --> int32
) is native({ CORE_AUDIO }) { * }


# Same CoreAudio function, specialised for an array of AudioDeviceID values.

sub AudioObjectGetPropertyDataDevices(
    uint32,
    AudioObjectPropertyAddress,
    uint32,
    Pointer,
    uint32 is rw,
    CArray[uint32]
    --> int32
) is native({ CORE_AUDIO })
  is symbol('AudioObjectGetPropertyData') { * }


# Same function again, this time outData is a CFStringRef*.

sub AudioObjectGetPropertyDataCFString(
    uint32,
    AudioObjectPropertyAddress,
    uint32,
    Pointer,
    uint32 is rw,
    CArray[Pointer]
    --> int32
) is native({ CORE_AUDIO })
  is symbol('AudioObjectGetPropertyData') { * }

sub AudioObjectGetPropertyDataUInt32(
    uint32,
    AudioObjectPropertyAddress,
    uint32,
    Pointer,
    uint32 is rw,
    CArray[uint32]
    --> int32
) is native({ CORE_AUDIO })
  is symbol('AudioObjectGetPropertyData') { * }
  
sub AudioObjectSetPropertyDataUInt32(
    uint32,
    AudioObjectPropertyAddress,
    uint32,
    Pointer,
    uint32,
    CArray[uint32]
    --> int32
) is native({ CORE_AUDIO })
  is symbol('AudioObjectSetPropertyData') { * }


sub CFStringGetCString(
    Pointer,
    CArray[uint8],
    long,
    uint32
    --> uint8
) is native({ CORE_FOUNDATION }) { * }


# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------

sub fourcc(Str:D $s --> uint32) {
    die "fourcc requires exactly four characters"
        unless $s.chars == 4;

    my @c = $s.ords;

    (
          (@c[0] +< 24)
        +| (@c[1] +< 16)
        +| (@c[2] +<  8)
        +|  @c[3]
    ).UInt;
}


constant kAudioObjectSystemObject = 1;

constant kAudioHardwarePropertyDevices =
    fourcc('dev#');

constant kAudioHardwarePropertyDefaultOutputDevice =
    fourcc('dOut');

constant kAudioObjectPropertyName =
    fourcc('lnam');

constant kAudioObjectPropertyScopeGlobal =
    fourcc('glob');

constant kAudioObjectPropertyScopeInput =
    fourcc('inpt');

constant kAudioObjectPropertyScopeOutput =
    fourcc('outp');

constant kAudioDevicePropertyStreams =
    fourcc('stm#');

constant kAudioHardwarePropertyDefaultInputDevice =
    fourcc('dIn ');

constant kAudioObjectPropertyElementMain = 0;

constant kCFStringEncodingUTF8 = 0x08000100;


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

sub property-address(
    uint32 $selector,
    uint32 $scope = kAudioObjectPropertyScopeGlobal
    --> AudioObjectPropertyAddress
) {
    AudioObjectPropertyAddress.new(
        mSelector => $selector,
        mScope    => $scope,
        mElement  => kAudioObjectPropertyElementMain
    );
}


sub default-device-id(
    uint32 $selector
    --> uint32
) {
    my $address =
        property-address($selector);

    my $value = CArray[uint32].new;
    $value[0] = 0;

    my uint32 $size = nativesizeof(uint32);

    my $status = AudioObjectGetPropertyDataUInt32(
        kAudioObjectSystemObject,
        $address,
        0,
        Pointer,
        $size,
        $value
    );

    check-status(
        $status,
        "Getting default audio device"
    );

    $value[0];
}


sub device-id-by-name(
    Str:D $name
    --> uint32
) {
    # Switching by name requires exactly one matching device.
    my @matches =
        MacOS::AudioDevices.audio-devices().grep(
            *.<name> eq $name
        );

    die "Audio device '$name' not found"
        unless @matches;

    die "Multiple audio devices named '$name' found"
        if @matches.elems > 1;

    @matches[0]<id>;
}


sub check-status(
    int32 $status,
    Str:D $operation
) {
    die "$operation failed with CoreAudio status $status"
        if $status != 0;
}


sub cfstring-to-str(
    Pointer $cfstring
    --> Str
) {
    return '' unless $cfstring;

    constant BUFFER-SIZE = 4096;

    my $buffer = CArray[uint8].new;

    # Force allocation of the whole buffer.
    $buffer[BUFFER-SIZE - 1] = 0;

    my $ok = CFStringGetCString(
        $cfstring,
        $buffer,
        BUFFER-SIZE,
        kCFStringEncodingUTF8
    );

    die "Unable to convert CoreAudio device name to UTF-8"
        unless $ok;

    my @bytes;

    for ^BUFFER-SIZE -> $i {
        last if $buffer[$i] == 0;

        @bytes.push($buffer[$i]);
    }

    Buf.new(@bytes).decode('utf8');
}


sub device-name(
    uint32 $device-id
    --> Str
) {
    my $address =
        property-address(kAudioObjectPropertyName);

    my uint32 $size = nativesizeof(Pointer);

    my $value = CArray[Pointer].new;
    $value[0] = Pointer;

    my $status = AudioObjectGetPropertyDataCFString(
        $device-id,
        $address,
        0,
        Pointer,
        $size,
        $value
    );

    check-status(
        $status,
        "Reading name of audio device $device-id"
    );

    die "CoreAudio returned no name for audio device $device-id"
        unless $value[0];

    cfstring-to-str($value[0]);
}


sub device-has-streams(
    uint32 $device-id,
    uint32 $scope
    --> Bool
) {
    my $address =
        property-address(
            kAudioDevicePropertyStreams,
            $scope
        );

    my uint32 $size = 0;

    my $status = AudioObjectGetPropertyDataSize(
        $device-id,
        $address,
        0,
        Pointer,
        $size
    );

    check-status(
        $status,
        "Checking stream configuration for audio device $device-id"
    );

    $size > 0;
}


# --------------------------------------------------------------------------
# Public API
# --------------------------------------------------------------------------

method audio-devices( --> Array )  
{
    my $address =
        property-address(kAudioHardwarePropertyDevices);

    my uint32 $size = 0;

    my $status = AudioObjectGetPropertyDataSize(
        kAudioObjectSystemObject,
        $address,
        0,
        Pointer,
        $size
    );

    check-status(
        $status,
        'Getting CoreAudio device list size'
    );

    return [] unless $size;

    my $count =
        $size div nativesizeof(uint32);

    my $devices = CArray[uint32].new;

    # Allocate enough space for CoreAudio to fill.
    $devices[$count - 1] = 0;

    $status = AudioObjectGetPropertyDataDevices(
        kAudioObjectSystemObject,
        $address,
        0,
        Pointer,
        $size,
        $devices
    );

    check-status(
        $status,
        'Getting CoreAudio device list'
    );

    my @result;

    for ^$count -> $i {
        my uint32 $id = $devices[$i];

        @result.push({
            id   => $id,
            name => device-name($id)
        });
    }

    @result;
}

method audio-input-devices( --> Array )
{
    self.audio-devices().grep(
        *.<id>.&device-has-streams( kAudioObjectPropertyScopeInput )
    ).Array;
}

method audio-output-devices( --> Array )
{
    self.audio-devices().grep(
        *.<id>.&device-has-streams( kAudioObjectPropertyScopeOutput )
    ).Array;
}

method duplex-audio-devices( --> Array )
{
    my @input-devices  = self.audio-input-devices();
    my @output-devices = self.audio-output-devices();

    # A duplex device id must exist in both input and output sets.
    my Set $duplex-device-ids =
        @input-devices.map( *.<id> ) ∩ @output-devices.map( *.<id> );

    @input-devices.grep(
        *.<id> ∈ $duplex-device-ids
    ).Array;
}

method active-input-device( --> Hash )
{
    my uint32 $id =
        default-device-id(
            kAudioHardwarePropertyDefaultInputDevice
        );

    {
        id   => $id,
        name => device-name($id)
    }
}


method active-output-device( --> Hash )
{
    my uint32 $id =
        default-device-id(
            kAudioHardwarePropertyDefaultOutputDevice
        );

    {
        id   => $id,
        name => device-name($id)
    }
}

multi method set-output-device( Str:D $name --> Bool )
{
    my uint32 $device-id = device-id-by-name($name);

    self.set-output-device( $device-id )

}

multi method set-output-device( Int:D $device-id --> Bool )
{
    my $address =
        property-address(
            kAudioHardwarePropertyDefaultOutputDevice
        );

    my $value = CArray[uint32].new;
    $value[0] = $device-id;

    my $status = AudioObjectSetPropertyDataUInt32(
        kAudioObjectSystemObject,
        $address,
        0,
        Pointer,
        nativesizeof(uint32),
        $value
    );

    check-status(
        $status,
        "Switching audio output to '$device-id'"
    );

    True;
}