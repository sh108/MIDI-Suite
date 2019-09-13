#ifndef MIDI_UTIL_H
#define MIDI_UTIL_H

#include <stdint.h>

namespace MIDI
{

void convert8to7Bits( const uint8_t *src, uint8_t *dst, int size )
{
    if( size < 1 || 7 < size ) return;

    dst[0] = 0;
    for( int i = 0; i < size; i++ ){
        dst[0] <<= 1;
        dst[0]  |= ( ( src[i] >> 7 ) & 0x1 );
        dst[i+1] = 0x7f & src[i];
    }

    for( int i = size; i < 7; i++ ){
        dst[0] <<= 1;
    }
}

void convert7to8Bits( const uint8_t *src, uint8_t *dst, int size )
{
    if( size < 2 || 8 < size ) return;

    uint8_t signByte = src[0];

    size--;
    signByte >>= ( 7 - size );

    for( int i = (size-1); i >= 0; i-- ){
        dst[i] = (( signByte & 0x1 ) << 7 ) | ( src[i+1] & 0x7f );
        signByte >>= 1;
    }
}

}

#endif /* MIDI_UTIL_H */
