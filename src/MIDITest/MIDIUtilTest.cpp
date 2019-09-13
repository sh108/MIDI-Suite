#include <iostream>
#include <cstring>
#include <fstream>

#include <CppUTest/TestHarness.h>

#include "../MIDI/MIDIUtil.h"

using namespace MIDI;

TEST_GROUP(MIDUtilTest){};

TEST(MIDUtilTest, convert78)
{
    const uint8_t data[] = { 0x84, 0xfd, 0x01, 0xa9, 0xd2, 0x7a, 0xf3 };

    const uint8_t converted0[] = { 0b01101101,
                                   static_cast<uint8_t>(data[0] & 0x7f),
                                   static_cast<uint8_t>(data[1] & 0x7f),
                                   static_cast<uint8_t>(data[2] & 0x7f),
                                   static_cast<uint8_t>(data[3] & 0x7f),
                                   static_cast<uint8_t>(data[4] & 0x7f),
                                   static_cast<uint8_t>(data[5] & 0x7f),
                                   static_cast<uint8_t>(data[6] & 0x7f)
    };

    const uint8_t converted1[] = { 0b01101000,
                                   static_cast<uint8_t>(data[0] & 0x7f),
                                   static_cast<uint8_t>(data[1] & 0x7f),
                                   static_cast<uint8_t>(data[2] & 0x7f),
                                   static_cast<uint8_t>(data[3] & 0x7f)
    };

    uint8_t *workBuf1 = new uint8_t[16];
    uint8_t *workBuf2 = new uint8_t[16];

    MIDI::convert8to7Bits( data, workBuf1, sizeof(data) / sizeof(uint8_t) );
    MEMCMP_EQUAL( converted0, workBuf1, sizeof(converted0) / sizeof(uint8_t) );

    MIDI::convert7to8Bits( workBuf1, workBuf2, sizeof(converted0) / sizeof(uint8_t) );
    MEMCMP_EQUAL( data, workBuf2, sizeof(data) / sizeof(uint8_t) );

    MIDI::convert8to7Bits( data, workBuf1, 4 );
    MEMCMP_EQUAL( converted1, workBuf1, sizeof(converted1) / sizeof(uint8_t) );

    MIDI::convert7to8Bits( workBuf1, workBuf2, 5 );
    MEMCMP_EQUAL( data, workBuf2, 4 );

    delete[] workBuf1;
    delete[] workBuf2;

}

IGNORE_TEST(MIDUtilTest, fileread)
{
    std::ifstream originalfo( "original.bin" , std::ios::binary );

    std::ifstream convertedfo( "converted.bin" , std::ios::binary );

    if( !originalfo.is_open() ){
        FAIL( "No original file not exist" );
        return;
    }

    if( !convertedfo.is_open() ){
        FAIL( "No converted file not exist" );
        return;
    }

    originalfo.seekg(0, std::fstream::end);
    convertedfo.seekg(0, std::fstream::end);
    std::size_t originalSize = originalfo.tellg();
    std::size_t convertedSize = convertedfo.tellg();

    originalfo.seekg(0, std::fstream::beg);
    convertedfo.seekg(0, std::fstream::beg);

    uint8_t *original = new uint8_t[originalSize];
    uint8_t *converted = new uint8_t[convertedSize];
    uint8_t *workBuf = new uint8_t[convertedSize];

    originalfo.read( (char*)original, originalSize );
    convertedfo.read( (char*)converted, convertedSize );

    originalfo.close();
    convertedfo.close();

    int size = convertedSize;
    int idx = 0;

    while( size > 0 ){
        MIDI::convert7to8Bits( converted + 8*idx, workBuf + 7*idx, 8 );
        size -= 8;
        idx++;
    }

    MEMCMP_EQUAL( original, workBuf, originalSize );

    
    delete[] original;
    delete[] converted;
    delete[] workBuf;

}
