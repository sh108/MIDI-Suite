#include <CppUTest/TestHarness.h>

#include <cstring>
#include <vector>

#include "../MIDI/MIDIMessage.h"
#include "../MIDI/MIDIStream.h"

using namespace MIDI;

static int clockCount = 0;
static std::vector<NoteMessage> noteMsgs(16);
static std::vector<ControlChangeMessage> ccMsgs(16);
static std::vector<ProgramChangeMessage> pcMsgs(16);
static std::vector<PitchBendMessage> bendMsgs(16);
static uint8_t sysExMsgBuf[MIDI::MaxSysExBufferSize];


struct MIDIMock : MIDIStreamDelegate
{
    void receiveNoteOffMessage( const MIDIStream*, const NoteMessage& msg )
    {
        noteMsgs.push_back( msg );
    }

    void receiveNoteOnMessage( const MIDIStream*, const NoteMessage& msg )
    {
        noteMsgs.push_back( msg );
    }

    void receiveControlChangeMessage( const MIDIStream*, const ControlChangeMessage& msg )
    {
        ccMsgs.push_back( msg );
    }

    void receiveProgramChangeMessage( const MIDIStream*, const ProgramChangeMessage& msg )
    {
        pcMsgs.push_back( msg );
    }

    void receivePitchBendMessage( const MIDIStream*, const PitchBendMessage& msg )
    {
        bendMsgs.push_back( msg );
    }

    void receiveSystemRealTimeMessage( const MIDIStream*, uint8_t data )
    {
        switch( data ){
        case MIDI::Clock:
            clockCount++;
            break;
        default:
            break;
        }
    }

    void receiveSystemExclusiveMessage( const MIDIStream*, const uint8_t *data, int size )
    {
        
        std::memcpy( sysExMsgBuf, data, size );
    }

};

TEST_GROUP(MIDStreamTest){};

TEST(MIDStreamTest, ReceiveNoteOnf)
{
    const uint8_t msg[] = { 0x84, 0x64, 0x00, 0x92, 0x40, 0x21, 0x75, 0x00 };

    noteMsgs.clear();

    MIDIStream stream;
    MIDIMock mock;
    stream.setDelegate( &mock );
    stream.analyze( msg, sizeof(msg) / sizeof(uint8_t) );

    BYTES_EQUAL( 4, noteMsgs[0].statusByte.ch );
    BYTES_EQUAL( 0x64, noteMsgs[0].note );
    BYTES_EQUAL( 0, noteMsgs[0].velocity );

    BYTES_EQUAL( 2, noteMsgs[1].statusByte.ch );
    BYTES_EQUAL( 0x40, noteMsgs[1].note );
    BYTES_EQUAL( 0x21, noteMsgs[1].velocity );

    BYTES_EQUAL( 2, noteMsgs[2].statusByte.ch );
    BYTES_EQUAL( 0x75, noteMsgs[2].note );
    BYTES_EQUAL( 0x00, noteMsgs[2].velocity );
}

TEST(MIDStreamTest, ReceiveControlChange)
{
    const uint8_t msg[] = { 0xb0, 0x64, 0x12, 0x56, 0x40, 0xbe, 0x79, 0x41 };

    ccMsgs.clear();

    MIDIStream stream;
    MIDIMock mock;
    stream.setDelegate( &mock );
    stream.analyze( msg, sizeof(msg) / sizeof(uint8_t) );

    BYTES_EQUAL( 0, ccMsgs[0].statusByte.ch );
    BYTES_EQUAL( 0x64, ccMsgs[0].number );
    BYTES_EQUAL( 0x12, ccMsgs[0].data );

    BYTES_EQUAL( 0, ccMsgs[1].statusByte.ch );
    BYTES_EQUAL( 0x56, ccMsgs[1].number );
    BYTES_EQUAL( 0x40, ccMsgs[1].data );

    BYTES_EQUAL( 0xe, ccMsgs[2].statusByte.ch );
    BYTES_EQUAL( 0x79, ccMsgs[2].number );
    BYTES_EQUAL( 0x41, ccMsgs[2].data );
}

TEST(MIDStreamTest, ReceiveProgramChange)
{
    const uint8_t msg[] = { 0xc5, 0x64, 0x12, 0x56, 0xc0, 0x3e, 0xc9, 0x40 };

    pcMsgs.clear();

    MIDIStream stream;
    MIDIMock mock;
    stream.setDelegate( &mock );
    stream.analyze( msg, sizeof(msg) / sizeof(uint8_t) );

    BYTES_EQUAL( 5, pcMsgs[0].statusByte.ch );
    BYTES_EQUAL( 0x64, pcMsgs[0].number );

    BYTES_EQUAL( 5, pcMsgs[1].statusByte.ch );
    BYTES_EQUAL( 0x12, pcMsgs[1].number );

    BYTES_EQUAL( 5, pcMsgs[2].statusByte.ch );
    BYTES_EQUAL( 0x56, pcMsgs[2].number );

    BYTES_EQUAL( 0, pcMsgs[3].statusByte.ch );
    BYTES_EQUAL( 0x3e, pcMsgs[3].number );

    BYTES_EQUAL( 9, pcMsgs[4].statusByte.ch );
    BYTES_EQUAL( 0x40, pcMsgs[4].number );

}

TEST(MIDStreamTest, ReceivePitchBend)
{
    const uint8_t msg[] = { 0xe2, 0x45, 0x01, 0xe6, 0x23, 0x22, 0x54, 0x31 };

    bendMsgs.clear();

    MIDIStream stream;
    MIDIMock mock;
    stream.setDelegate( &mock );
    stream.analyze( msg, sizeof(msg) / sizeof(uint8_t) );

    BYTES_EQUAL( 2, bendMsgs[0].statusByte.ch );
    BYTES_EQUAL( 0x45, bendMsgs[0].lsb );
    BYTES_EQUAL( 0x01, bendMsgs[0].msb );

    BYTES_EQUAL( 6, bendMsgs[1].statusByte.ch );
    BYTES_EQUAL( 0x23, bendMsgs[1].lsb );
    BYTES_EQUAL( 0x22, bendMsgs[1].msb );

    BYTES_EQUAL( 6, bendMsgs[2].statusByte.ch );
    BYTES_EQUAL( 0x54, bendMsgs[2].lsb );
    BYTES_EQUAL( 0x31, bendMsgs[2].msb );
}

TEST(MIDStreamTest, ReceiveClock)
{
    const uint8_t msg[] = { MIDI::Clock, MIDI::Start, MIDI::Clock, MIDI::Clock, MIDI::Continue, MIDI::Clock, MIDI::Clock, MIDI::Stop};
    MIDIStream stream;
    MIDIMock mock;
    clockCount = 0;

    stream.setDelegate( &mock );
    stream.analyze( msg, sizeof(msg) / sizeof(uint8_t) );

    LONGS_EQUAL( clockCount, 5 );

}

TEST(MIDStreamTest, ReceiveSysEx)
{
    const uint8_t msg[] = { MIDI::StartSysEx, 0x45, 0x01, 0x66, 0x23, 0x22, 0x54, MIDI::EndSysEx };

    MIDIStream stream;
    MIDIMock mock;
    stream.setDelegate( &mock );
    stream.analyze( msg, sizeof(msg) / sizeof(uint8_t) );

    MEMCMP_EQUAL( msg, &sysExMsgBuf[0], sizeof(msg) / sizeof(uint8_t) );

}
