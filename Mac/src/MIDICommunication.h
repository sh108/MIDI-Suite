//
// MIDICommunication.h
//
// Created by sh108
// Copyright (c) 2013 sh108. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>
#import "MIDIEngineAssignNumbers.h"

typedef void (^MIDICompleteBlock_t)(void);

@protocol MIDICommunicationDelegate;

#pragma mark -
////////////////////////////////////////////////////////////////
#pragma mark interface "MIDICommunication"
////////////////////////////////////////////////////////////////

@interface MIDICommunication : NSObject
{
    MIDIPortRef		inputPortRef;
    MIDIPortRef		outputPortRef;
    
    MIDIEndpointRef destinationRef;
    MIDIEndpointRef sourceRef;
    
    dispatch_semaphore_t receiveWaitSemaphore;
}

@property(nonatomic, assign)id<MIDICommunicationDelegate>delegate;
@property(nonatomic, readonly, assign)BOOL isReceiveWaiting;

#pragma mark -
#pragma mark Methods for MIDICommunication

- (MIDIStatus)createOutputPort:(NSString*)name
                    clientPort:(MIDIClientRef)clientRef;

- (MIDIStatus)disposeOutput;

- (MIDIStatus)createInputPort:(NSString*)name
                   clientPort:(MIDIClientRef)clientRef;

- (MIDIStatus)disposeInput;

- (void)setSourcePoint:(MIDIEndpointRef)srcRef;
- (void)setDestinationPoint:(MIDIEndpointRef)dstRef;

- (MIDIStatus)connectSourcePoint;
- (MIDIStatus)disconnectSourcePoint;

- (MIDIStatus)sendMessage:(Byte)data;

- (MIDIStatus)asyncSendSysexMessage:(void*)message
                             length:(UInt32)length
                         completion:(MIDICompleteBlock_t)completion;

- (MIDIStatus)syncSendSysexWithData:(void*)data
                             length:(UInt32)length
                  timeoutRetryCount:(NSUInteger)timeoutRetryCnt
                      retryInterval:(NSTimeInterval)interval
                       txRetryCount:(NSUInteger)txRetryCnt;

- (long)waitUntilData:(NSTimeInterval)waitTime;
- (void)signal;

////////////////////////////////////////////////////////////////
#pragma mark iOS only
////////////////////////////////////////////////////////////////
#ifdef __MIDINetworkSession_h__

/*
- (OSStatus)connectWifiEndPoint;
*/

#endif
@end

#pragma mark -
////////////////////////////////////////////////////////////////
#pragma mark protocol "MIDICommunicationDelegate"
////////////////////////////////////////////////////////////////

@protocol MIDICommunicationDelegate <NSObject>

@optional
- (void)midiReceive:(MIDICommunication*)midiComm packetList:(const MIDIPacketList*)packetList srcRefCon:(void*)srcRefCon;

@end