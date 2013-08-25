//
// MIDICommunication.m
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

#import "MIDICommunication.h"

////////////////////////////////////////////////////////////////
#pragma mark "MIDICommunication"
////////////////////////////////////////////////////////////////
#pragma mark -
@implementation MIDICommunication

static MIDICompleteBlock_t asyncSendCompletion = nil;

@synthesize delegate = _delegate;
@synthesize isReceiveWaiting = _isReceiveWaiting;

- (void)dealloc
{
    _delegate = nil;
    asyncSendCompletion = nil;
    
    [self disconnectSourcePoint];
    [self disposeInput];
    [self disposeOutput];
    
    if ( receiveWaitSemaphore ) {
        dispatch_release(receiveWaitSemaphore);
    }
    
    [super dealloc];
}

void midiReadProc(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon)
{
    MIDICommunication *midiComm = (MIDICommunication*)readProcRefCon;
    
    UInt16 length = pktlist->packet->length;
    
    for (UInt16 i = 0; i<length; i++) {
        NSLog(@"receive[%d]:%02X",i,pktlist->packet->data[i]);
    }
    
    if ([midiComm.delegate respondsToSelector:@selector(midiReceive:packetList:srcRefCon:)]) {
        [midiComm.delegate midiReceive:midiComm packetList:pktlist srcRefCon:srcConnRefCon];
    }

}

- (MIDIStatus)createOutputPort:(NSString*)name clientPort:(MIDIClientRef)clientRef
{
    MIDIPortRef outputRef;
    
    MIDIStatus err = errSecSuccess;
    
    err=(MIDIStatus)MIDIOutputPortCreate(clientRef, (CFStringRef)name, &outputRef);
    if(err){
        return err;
    }
    
    outputPortRef = outputRef;

    return outputRef;
    
}

- (MIDIStatus)disposeOutput
{
    MIDIStatus err = errSecSuccess;
    
    if (destinationRef) {
        err=(MIDIStatus)MIDIEndpointDispose(destinationRef);
        if (err) {
        }else{
            destinationRef = 0;
        }
    }
    
    if (outputPortRef) {
        err=(MIDIStatus)MIDIPortDispose(outputPortRef);
        if (err) {
        }else{
            outputPortRef = 0;
        }
    }

    return err;
    
}

- (MIDIStatus)createInputPort:(NSString*)name clientPort:(MIDIClientRef)clientRef
{
    MIDIPortRef inputRef;
    
    MIDIStatus err = errSecSuccess;
    
    err = (MIDIStatus)MIDIInputPortCreate(clientRef, (CFStringRef)name, midiReadProc, self, &inputRef);
    if(err){
        return kMIDIReturnInvalidPort;
    }
    
    inputPortRef = inputRef;
    
    return err;
    
}

- (MIDIStatus)disposeInput
{
    MIDIStatus err = errSecSuccess;
    
    if (sourceRef) {
        err=(MIDIStatus)MIDIEndpointDispose(sourceRef);
        if (err) {
        }else{
            sourceRef = 0;
        }
    }

    if (inputPortRef) {
        err=(MIDIStatus)MIDIPortDispose(inputPortRef);
        if (err) {
        }else{
            inputPortRef = 0;
        }
    }
    
    return err;
    
}

- (void)setSourcePoint:(MIDIEndpointRef)srcRef
{
    sourceRef = srcRef;
}

- (void)setDestinationPoint:(MIDIEndpointRef)dstRef
{
    destinationRef = dstRef;
}

- (MIDIStatus)connectSourcePoint
{
    MIDIStatus err = noErr;
    
    err = MIDIPortConnectSource(inputPortRef, sourceRef, NULL);
    
    return err;
}

- (MIDIStatus)disconnectSourcePoint
{
    MIDIStatus err = noErr;
    
    err = MIDIPortDisconnectSource(inputPortRef, sourceRef);
    sourceRef = 0;
    
    return err;
}

void midiSysexSendCompletionProc( MIDISysexSendRequest *request )
{
    if (request) {
        free(request);
    }
    
    if ( asyncSendCompletion ) {
        asyncSendCompletion();
    }
}

- (MIDIStatus)sendMessage:(Byte)data
{
    
    MIDIStatus err;
    
    // create MIDIPacketList
    ByteCount bufferSize = 20;
    Byte packetListBuffer[bufferSize];
    MIDIPacketList *packetListPtr = (MIDIPacketList *)packetListBuffer;
    MIDIPacket *packet = MIDIPacketListInit(packetListPtr);
    //    MIDITimeStamp time = AudioGetCurrentHostTime();
    MIDITimeStamp time = 0;
    
    packet = MIDIPacketListAdd(packetListPtr, bufferSize, packet, time, sizeof(data), &data);
    
    for (int i=0; i<packet->length; i++) {
        NSLog(@"send[%d]:%02X",i,packetListPtr->packet->data[i]);
    }
    
    err = MIDISend(outputPortRef, destinationRef, packetListPtr);
    if (err != noErr) {
        NSLog(@"MIDISend err = %d", err);
        return err;
    }
    
    return noErr;
}

//==============================================================================
// MIDI Transmission　＋　Receive
//==============================================================================

- (MIDIStatus)asyncSendSysexMessage:(void*)message
                             length:(UInt32)length
                         completion:(MIDICompleteBlock_t)completion
{
    
    MIDIStatus err = noErr;
    
    if ( outputPortRef == 0 ) {
        return kMIDIInvalidPort;
    }
    
    if ( destinationRef == 0 ) {
        return kMIDIWrongEndpointType;
    }
    
    for (int i = 0; i<length; i++) {
        Byte* data = (Byte*)message;
        NSLog(@"message[%d]:%02X",i,data[i]);
    }
    
    if ( completion ) {
        asyncSendCompletion = completion;
    }else{
        asyncSendCompletion = nil;
    }
    
    MIDISysexSendRequest *sysExReq = (MIDISysexSendRequest*)malloc(sizeof(MIDISysexSendRequest));
    sysExReq->destination = destinationRef;
    sysExReq->data = (Byte*)message;
    sysExReq->bytesToSend = length;
    sysExReq->complete = 0;
    sysExReq->completionProc = midiSysexSendCompletionProc;
    sysExReq->completionRefCon = NULL;
    
    err = MIDISendSysex(sysExReq);
    if (err != noErr) {
        NSLog(@"MIDISend err = %d", err);
        return err;
    }
    
    return err;
}

- (MIDIStatus)syncSendSysexWithData:(void*)data
                             length:(UInt32)length
                  timeoutRetryCount:(NSUInteger)timeoutRetryCnt
                      retryInterval:(NSTimeInterval)interval
                       txRetryCount:(NSUInteger)txRetryCnt
{
    
    MIDIStatus err = noErr;
	UInt8 retryCountOfTimeOut      = 0;
	UInt8 retryCountOfTxErr        = 0;
	UInt8 retryMaxCountOfTxErr     = txRetryCnt;
    
	// wait for MIDI receive
    while(retryCountOfTxErr <= retryMaxCountOfTxErr){
        
        // Transmit SysEx Message
        [self asyncSendSysexMessage:data length:length completion:nil];
        retryCountOfTxErr++;
        
        if (receiveWaitSemaphore == nil) {
            receiveWaitSemaphore = dispatch_semaphore_create(0);
        }
        
		while ( (err = (MIDIStatus)[self waitUntilData:interval]) > 0){
            
            if( retryCountOfTimeOut >= timeoutRetryCnt){
                
                return kMIDIReturnTimeoutError;
                
            }
            
            retryCountOfTimeOut++;
            
            [self asyncSendSysexMessage:data length:length completion:nil];
        }

        if ( err == noErr ) {
            break;
        }else if(retryCountOfTxErr == retryMaxCountOfTxErr){
            return kMIDIReturnCommunicationError;
        }
    }
    
    return kMIDIReturnComplete;

}

- (long)waitUntilData:(NSTimeInterval)waitTime
{
    MIDIStatus err = noErr;
    
    _isReceiveWaiting = YES;
    
    if ( dispatch_semaphore_wait(receiveWaitSemaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * waitTime)) ) {
        _isReceiveWaiting = NO;
        err = kMIDIReturnTimeoutError;
    }
    
    return err;
}

- (void)signal
{
    if ( _isReceiveWaiting == NO ) {
        return;
    }
    
    if ( receiveWaitSemaphore ) {
        dispatch_semaphore_signal(receiveWaitSemaphore);
    }
}

////////////////////////////////////////////////////////////////
#pragma mark iOS only
////////////////////////////////////////////////////////////////
#ifdef __MIDINetworkSession_h__
/*
- (OSStatus)connectWifiEndPoint
{
    OSStatus err = noErr;
    
    MIDINetworkSession *session = [MIDINetworkSession defaultSession];
    session.enabled = YES;
    session.connectionPolicy = MIDINetworkConnectionPolicy_Anyone;
    sourceRef = [session sourceEndpoint];
    MIDIPortConnectSource(inputPortRef, sourceRef, NULL);
    
    destinationRef = [session destinationEndpoint];
    
    return err;
}
*/
#endif

@end
