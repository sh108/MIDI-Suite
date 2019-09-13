#!/usr/bin/env python

#coding:utf-8

import sys
import os


def convert8to7Bits( srcBytes ):
    
    size = len(srcBytes)

    if  size < 1 or 7 < size:
        print( "[convert8to7Bits] Error : Invalid size" )
        return bytes()

    dst = bytearray()
    dst.append(0)

    for idx in range( size ):
        dst[0] <<= 1
        dst[0]  |= ( ( srcBytes[idx] >> 7 ) & 0x1 )
        dst.append( 0x7f & srcBytes[idx] )

    for idx in range( size, 7 ):
        dst[0] <<= 1

    return dst

def main():

    outFile = 'out.bin'
    args = sys.argv

    if len(args) < 2:
        return
    elif len(args) == 3:
        outFile = args[1]

    with open( args[1], 'rb') as rb:
        src = rb.read()
        size = len(src)
        print( size )
        with open( outFile, 'wb') as wb:
            idx = 0
            while size > 0:
                if size < 7 :
                    wb.write( convert8to7Bits(src[7*idx:len(src)]) )
                else:
                    wb.write( convert8to7Bits(src[7*idx:7*(idx+1)]) )
                size -= 7
                idx += 1

if __name__ == '__main__':
    main()
