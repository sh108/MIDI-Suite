#ifndef MIDI_STREAM_H
#define MIDI_STREAM_H

#include <stdint.h>
#include "MIDIMessage.h"

namespace MIDI
{
const int MaxSysExBufferSize = 256;

struct MIDIStreamDelegate;

class MIDIStream
{
    MIDIStreamDelegate *delegate;
    MIDIMessage rcvMsg;
    int     dataLength;
    int     maxDataLength;

    void updateMaxDataLength( uint8_t stat );
    void dispatchMessage( void );

public:
    MIDIStream();

    void setDelegate( MIDIStreamDelegate* ref ){ this->delegate = ref; }
    void analyze( const uint8_t* data, int size );
};

struct MIDIStreamDelegate
{
    virtual void receiveNoteOffMessage( const MIDIStream*, const NoteMessage& msg ){}
    virtual void receiveNoteOnMessage( const MIDIStream*, const NoteMessage& msg ){}
    virtual void receiveControlChangeMessage( const MIDIStream*, const ControlChangeMessage& msg ){}
    virtual void receiveProgramChangeMessage( const MIDIStream*, const ProgramChangeMessage& msg ){}
    virtual void receivePitchBendMessage( const MIDIStream*, const PitchBendMessage& msg ){}
    virtual void receiveSystemRealTimeMessage( const MIDIStream*, uint8_t data ){}

    virtual void receiveSystemExclusiveMessage( const MIDIStream*, const uint8_t *data, int size ){}
};

}

#endif /* MIDI_STREAM_H */
