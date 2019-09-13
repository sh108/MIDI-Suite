#include "MIDIStream.h"

#include <stddef.h>
//#include <iostream>

using namespace MIDI;

static uint8_t sysExBuffer[MaxSysExBufferSize];

MIDIStream::MIDIStream( void ) :
delegate(NULL),
rcvMsg(),
dataLength(0),
maxDataLength(0)
{

}

void MIDIStream::updateMaxDataLength( uint8_t stat )
{
    if( stat == ProgramChange || stat == ChannelPress ){
        this->maxDataLength = 1;
    }else if( stat == StartSysEx ){
        this->maxDataLength = MaxSysExBufferSize;
    }else{
        this->maxDataLength = 2;
    }
}

void MIDIStream::analyze( const uint8_t* data, int size )
{
    if( this->delegate ){
        while( size ){
            if( ( *data & 0xf8 ) == 0xf8 ){
                this->delegate->receiveSystemRealTimeMessage( this, *data );
            }else if( *data == StartSysEx ){
                this->rcvMsg.statusByte = *data;
                this->dataLength = 1;
                this->updateMaxDataLength( this->rcvMsg.statusByte & 0xf0 );
                sysExBuffer[0] = StartSysEx;
            }else if( ( this->rcvMsg.statusByte == StartSysEx ) && ( *data == EndSysEx ) ){
                sysExBuffer[this->dataLength] = *data;
                this->dataLength++;
                this->delegate->receiveSystemExclusiveMessage( this, sysExBuffer, this->dataLength );
                this->dataLength = 0;
            }else if( ( *data & 0x80 ) ){
                this->rcvMsg.statusByte = *data;
                this->dataLength = 0;
                this->updateMaxDataLength( this->rcvMsg.statusByte.data & 0xf0 );
            }else{
                if( this->rcvMsg.statusByte.data ){
                    if( this->rcvMsg.statusByte == StartSysEx ){
                        sysExBuffer[this->dataLength] = *data;
                        this->dataLength++;
                        if( this->dataLength >= this->maxDataLength ){
                            this->delegate->receiveSystemExclusiveMessage( this, sysExBuffer, this->dataLength );
                            this->dataLength = 0;
                        }
                    }else{
                        this->rcvMsg.data[this->dataLength] = *data;
                        this->dataLength++;
                        if( this->dataLength >= this->maxDataLength ){
                            this->dispatchMessage();
                            this->dataLength = 0;
                        }
                    }
                }
            }
            size--;
            data++;
        }
    }
}

void MIDIStream::dispatchMessage( void )
{
    switch( this->rcvMsg.statusByte & 0xf0 ){
    case NoteOff:
        this->delegate->receiveNoteOffMessage( this, reinterpret_cast<const NoteMessage&>(this->rcvMsg) );
        break;
    case NoteOn:
    {
        const NoteMessage& noteMsg = reinterpret_cast<const NoteMessage&>(this->rcvMsg);
        if( noteMsg.velocity ){
            this->delegate->receiveNoteOnMessage( this, noteMsg );
        }else{
            this->delegate->receiveNoteOffMessage( this, noteMsg );
        }
    }
        break;
    case ControlChange:
        this->delegate->receiveControlChangeMessage( this, reinterpret_cast<const ControlChangeMessage&>(this->rcvMsg) );
        break;
    case ProgramChange:
        this->delegate->receiveProgramChangeMessage( this, reinterpret_cast<const ProgramChangeMessage&>(this->rcvMsg) );
        break;
    case PitchBend:
       this->delegate->receivePitchBendMessage( this, reinterpret_cast<const PitchBendMessage&>(this->rcvMsg) );
        break;
    default:
        break;
    }
}