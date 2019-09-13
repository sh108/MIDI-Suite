#ifndef MIDI_MEASSAGE_H
#define MIDI_MEASSAGE_H

#include <stdint.h>

namespace MIDI
{

const uint8_t NoteOff       = 0x80;
const uint8_t NoteOn        = 0x90;
const uint8_t PolyKerPress  = 0xa0;
const uint8_t ControlChange = 0xb0;
const uint8_t ProgramChange = 0xc0;
const uint8_t ChannelPress  = 0xd0;
const uint8_t PitchBend     = 0xe0;

// System Common Message
const uint8_t StartSysEx      = 0xf0;
const uint8_t SongPosiPointer = 0xf2;
const uint8_t SongSelect      = 0xf2;
const uint8_t EndSysEx        = 0xf7;

// System RealTime Message
const uint8_t Clock    = 0xf8;
const uint8_t Start    = 0xfa;
const uint8_t Continue = 0xfb;
const uint8_t Stop     = 0xfc;

union MIDIStatusByte
{
    struct {
        uint8_t ch  : 4;
        uint8_t cmd : 4;
    };
    uint8_t data;

    MIDIStatusByte() : data(0){}

    MIDIStatusByte& operator = ( const uint8_t byte )
    {
        this->data = byte;
        return *this;
    }

    bool operator == ( const uint8_t byte )
    {
        return this->data == byte;
    }

    int32_t operator & ( const int32_t byte )
    {
        return this->data & byte;
    }
}; 

struct MIDIMessage
{
    MIDIStatusByte statusByte; 
    uint8_t data[2];

    MIDIMessage( void ) : statusByte(), data(){}
};

struct NoteMessage
{
    MIDIStatusByte statusByte; 
    uint8_t note;
    uint8_t velocity;
};

struct PolyKeyPressureMessage
{
    MIDIStatusByte statusByte; 
    uint8_t note;
    uint8_t press;
};

struct ControlChangeMessage
{
    MIDIStatusByte statusByte; 
    uint8_t number;
    uint8_t data;
};

struct ProgramChangeMessage
{
    MIDIStatusByte statusByte; 
    uint8_t number;
};

struct ChannelPressureMessage
{
    MIDIStatusByte statusByte; 
    uint8_t press;
};

struct PitchBendMessage
{
    MIDIStatusByte statusByte; 
    uint8_t lsb;
    uint8_t msb;
};

}

#endif /* MIDI_MEASSAGE_H */
