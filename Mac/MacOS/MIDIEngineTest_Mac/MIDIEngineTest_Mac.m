//
// MIDIEngineTest_Mac.m
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

#import "MIDIEngineTest_Mac.h"

typedef void (^AssertionCheck_t)(MIDICommunication *midiComm, const MIDIPacketList *packetList);

@interface MIDIEngineTest_Mac ()
{
    AssertionCheck_t assertCheckBlock;
    volatile BOOL isReceiveWaiting;
}
@end

@implementation MIDIEngineTest_Mac

- (void)midiReceive:(MIDICommunication*)midiComm packetList:(const MIDIPacketList *)packetList srcRefCon:(void *)srcRefCon
{
    if (assertCheckBlock) {
        assertCheckBlock(midiComm, packetList);
    }
}

- (void)communicationCommonProcess:(void(^)(void))mainProcess
                    assertionCheck:(AssertionCheck_t)assertionCheck
{
    
    isReceiveWaiting = YES;
    
    NSString *deviceName = nil;
    MIDIDeviceManager *deviceManager = [MIDIDeviceManager deviceManager];
    
    master.delegate = self;
    slave.delegate = self;
    
    for (ItemCount i = 0; i<[deviceManager getNumberOfMIDIDevices]; i++) {
        deviceName = [deviceManager getNameOfMIDIDeviceWithIndex:i];
        
        if ([deviceName isEqualToString:@"IAC Driver"] == YES) {
            MIDIClientRef client = [deviceManager createClient:@"com.sh108works.masterClient"];
            [master createOutputPort:@"com.sh108works.masterOutput"clientPort:client];
            [master createInputPort:@"com.sh108works.masterInput"clientPort:client];

            MIDIEndpointRef outPutRef = [deviceManager getDestinationWithDevice:i entity:0];
            [master setDestinationPoint:outPutRef];
            
            MIDIEndpointRef inputRef = [deviceManager getSourceWithDevice:i entity:1];
            [master setSourcePoint:inputRef];
            [master connectSourcePoint];
            break;
        }
    }
    
    STAssertTrue([deviceName isEqualToString:@"IAC Driver"], @"Please Setting \"IAC Driver\"");
    
    for (ItemCount i = 0; i<[deviceManager getNumberOfMIDIDevices]; i++) {
        deviceName = [deviceManager getNameOfMIDIDeviceWithIndex:i];
        if ([deviceName isEqualToString:@"IAC Driver"] == YES) {
            MIDIClientRef client = [deviceManager createClient:@"com.sh108works.slaveClient"];
            [slave createOutputPort:@"com.sh108works.slaveOutput"clientPort:client];
            [slave createInputPort:@"com.sh108works.slaveInput"clientPort:client];
            
            MIDIEndpointRef outPutRef = [deviceManager getDestinationWithDevice:i entity:1];
            [slave setDestinationPoint:outPutRef];
            
            MIDIEndpointRef inputRef = [deviceManager getSourceWithDevice:i entity:0];
            [slave setSourcePoint:inputRef];
            [slave connectSourcePoint];

            break;
        }
    }
    
    STAssertTrue([deviceName isEqualToString:@"IAC Driver"], @"Please Setting \"IAC Driver\"");
    
    if ( assertionCheck ) {
        assertCheckBlock = assertionCheck;
    }
    
    if(mainProcess){
        mainProcess();
    }
    
    while ( isReceiveWaiting ) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    master = [[MIDICommunication alloc] init];
    slave  = [[MIDICommunication alloc] init];
    
}

- (void)tearDown
{
    // Tear-down code here.
    
    [slave release];
    [master release];
    [super tearDown];
}

- (void)test01_Initialize
{
    STAssertNotNil(master, @"Cannot find MIDICommunication instance \"master\"");
    STAssertNotNil(slave, @"Cannot find MIDICommunication instance \"slave\"");
}

- (void)test02_Communication
{
    
    [self communicationCommonProcess:^{
        
        Byte byte[2] = {0xC3, 0x5A};
        NSData *masterTxData = [NSData dataWithBytes:byte length:2];

        [master syncSendSysexWithData:(void*)masterTxData.bytes
                               length:2
                    timeoutRetryCount:5
                        retryInterval:100
                         txRetryCount:5];
        
    }assertionCheck:^(MIDICommunication *midiComm, const MIDIPacketList *packetList) {
        
        if (midiComm == slave) {
            
            NSLog(@"Slave midiReceive");
            
            Byte *data = (Byte*)packetList->packet->data;
            
            STAssertEquals((Byte)0xC3, data[0], @"slave Rx mismatch data[0]:0x%02X",data[0]);
            STAssertEquals((Byte)0x5A, data[1], @"slave Rx mismatch data[1]:0x%02X",data[1]);
            
            Byte byte[2] = {0xA5, 0x3C};
            NSData *slaveTxData = [NSData dataWithBytes:byte length:2];
            [slave asyncSendSysexMessage:(void*)slaveTxData.bytes length:(UInt32)slaveTxData.length completion:nil];
            
        }else if(midiComm == master){
            
            NSLog(@"Master midiReceive");
            
            [master signal];
            
            Byte *data = (Byte*)packetList->packet->data;
            
            STAssertEquals((Byte)0xA5, data[0], @"master Rx mismatch data[0]:0x%02X",data[0]);
            STAssertEquals((Byte)0x3C, data[1], @"master Rx mismatch data[1]:0x%02X",data[1]);

            isReceiveWaiting = NO;
        }
        
    }];
    
}

@end
