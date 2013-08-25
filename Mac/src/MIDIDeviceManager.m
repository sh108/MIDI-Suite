//
// MIDIDeviceManager.h
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

#import "MIDIDeviceManager.h"

@implementation MIDIDeviceManager

@synthesize delegate = _delegate;

+ (MIDIDeviceManager*)deviceManager
{
    return [[[MIDIDeviceManager alloc] init] autorelease];
}

- (void)handleMIDIPropertyChanged:(const MIDINotification*)notification
{
    MIDIObjectPropertyChangeNotification* propertyChangedNotification = (MIDIObjectPropertyChangeNotification*)notification;
    NSLog(@"kMIDIMsgPropertyChanged:%d",propertyChangedNotification->objectType);
    MIDIStatus err = noErr;
    CFStringRef deviceName = NULL;
    
    // Get MIDI device reference
    MIDIDeviceRef devRef = (MIDIDeviceRef)(propertyChangedNotification->object);
    
    CFPropertyListRef outProperties;
    
    err = MIDIObjectGetProperties(devRef, &outProperties, YES);
    
    // Get MIDI device name
    err = MIDIObjectGetStringProperty( devRef, kMIDIPropertyName, &deviceName);
    
    if (err != noErr) {
        NSLog(@"err = %d", err);
    }
    
    NSLog(@"kMIDIMsgPropertyChanged:%@",outProperties);
    
    if ([_delegate respondsToSelector:@selector(midiPropertyChange:deviceRef:)]) {
        [_delegate midiPropertyChange:self deviceRef:devRef];
    }
}

static void midiNotificationProcess(const MIDINotification *notification, void *refCon)
{
    MIDIDeviceManager *midiDeviceManager = (MIDIDeviceManager*)refCon;
    
    switch (notification->messageID) {
        case kMIDIMsgSetupChanged:
            NSLog(@"kMIDIMsgSetupChanged");
            break;
        case kMIDIMsgObjectAdded:
        {
            MIDIObjectAddRemoveNotification* addRemoveNotification = (MIDIObjectAddRemoveNotification*)notification;
            NSLog(@"kMIDIMsgObjectAdded:%d",addRemoveNotification->parentType);
            NSLog(@"kMIDIMsgObjectAdded:%d",addRemoveNotification->childType);
        }
            break;
        case kMIDIMsgObjectRemoved:
        {
            MIDIObjectAddRemoveNotification* addRemoveNotification = (MIDIObjectAddRemoveNotification*)notification;
            NSLog(@"kMIDIMsgObjectRemoved:%d",addRemoveNotification->parentType);
            NSLog(@"kMIDIMsgObjectRemoved:%d",addRemoveNotification->childType);
        }
            break;
        case kMIDIMsgPropertyChanged:
            
            [midiDeviceManager handleMIDIPropertyChanged:notification];
            
            break;
        case kMIDIMsgThruConnectionsChanged:
            NSLog(@"kMIDIMsgThruConnectionsChanged");
            break;
        case kMIDIMsgSerialPortOwnerChanged:
            NSLog(@"kMIDIMsgSerialPortOwnerChanged");
            break;
        case kMIDIMsgIOError:
            NSLog(@"kMIDIMsgIOError");
            break;
            
        default:
            NSLog(@"unknown notification");
            break;
    }
}

- (MIDIClientRef)createClient:(NSString*)name
{
    MIDIClientRef clientRef;
    
    MIDIStatus err = errSecSuccess;
    
    err=(MIDIStatus)MIDIClientCreate((CFStringRef)name, midiNotificationProcess, self, &clientRef);
    if(err){
        return 0;
    }
    
    return clientRef;
    
}

- (MIDIStatus)disposeClient:(MIDIClientRef)clientRef
{
    MIDIStatus err = errSecSuccess;
    
    if (clientRef) {
        err=(MIDIStatus)MIDIClientDispose(clientRef);
        if (err) {
        }else{
            clientRef = 0;
        }
    }
    
    return err;
    
}

- (ItemCount)getNumberOfMIDIDevices
{
    return MIDIGetNumberOfDevices();
}

- (MIDIDeviceRef)getMIDIDevice:(ItemCount)index
{
    return MIDIGetDevice(index);
}

- (NSString*)getNameOfMIDIDeviceWithIndex:(ItemCount)index
{
    
    NSString *name;
    
    OSStatus err = noErr;
    CFStringRef nameRef = NULL;
    
    //Get MIDI Device reference
    MIDIDeviceRef devRef = MIDIGetDevice(index);
    
    //Get MIDI device name
    err = MIDIObjectGetStringProperty( devRef, kMIDIPropertyName, &nameRef);
    if (err != noErr) {
        NSLog(@"MIDIObjectGetStringProperty err = %d", err);
        return nil;
    }
    
    NSLog(@"connect = %@", nameRef);
    name = [NSString stringWithString:(NSString*)nameRef];
    
    CFRelease(nameRef);
    
    return name;
    
}

- (MIDIStatus)getMIDIDevices
{
    MIDIStatus err = noErr;
    CFStringRef strDeviceRef = NULL;
    CFStringRef strEndPointRef = NULL;
    
    // Get number of MIDI devices
    ItemCount count = MIDIGetNumberOfDevices();
    
    for (ItemCount i = 0; i < count; i++) {
        
        //Get MIDI device reference
        MIDIDeviceRef devRef = MIDIGetDevice(i);
        
        //Get MIDI device name
        err = MIDIObjectGetStringProperty( devRef, kMIDIPropertyName, &strDeviceRef);
        if (err != noErr) {
            NSLog(@"err = %d", err);
        }
        
        // Get number of MIDI entities
        ItemCount numEntities = MIDIDeviceGetNumberOfEntities(devRef);
        NSLog(@"numEntities:%ld",numEntities);
        
        for (NSInteger j = 0; j < numEntities; j++) {
            
            // Get MIDI entity reference
            MIDIEntityRef entityRef = MIDIDeviceGetEntity(devRef, j);
            
            // Get number of souece end points of MIDI entity
            ItemCount sourceCount = MIDIEntityGetNumberOfSources(entityRef);
            NSLog(@"sourceCount:%ld",sourceCount);
            for (NSInteger k = 0; k < sourceCount; k++) {
                
                // Get MIDI source point reference
                MIDIEndpointRef endPointRef = MIDIEntityGetSource(entityRef, k);
                
                // Get MIDI source point name
                err = MIDIObjectGetStringProperty(endPointRef, kMIDIPropertyName, &strEndPointRef);
                if (err != noErr) {
                    NSLog(@"err = %d", err);
                }
                
                SInt32 isOffline;
                err = MIDIObjectGetIntegerProperty(endPointRef, kMIDIPropertyOffline, &isOffline);
                if (err != noErr) {
                    NSLog(@"err = %d", err);
                }
                
                NSLog(@"Device = %@ / EndPoint = %@ / Offline = %d", strDeviceRef, strEndPointRef, isOffline);
                
                if (strEndPointRef) {
                    CFRelease(strEndPointRef);
                    strEndPointRef = NULL;
                }
            }
        }
        
        if (strDeviceRef) {
            CFRelease(strDeviceRef);
            strDeviceRef = NULL;
        }
    }
    
    return err;
}

- (MIDIEndpointRef)getSourceWithDevice:(ItemCount)deviceIndex
                                entity:(ItemCount)entityIndex
{
    MIDIEndpointRef srcPoint;
    
    MIDIDeviceRef devRef = MIDIGetDevice(deviceIndex);
    MIDIEntityRef devEty = MIDIDeviceGetEntity(devRef, entityIndex);
    srcPoint = MIDIEntityGetSource(devEty, 0);
    
    return srcPoint;
}

- (MIDIEndpointRef)getDestinationWithDevice:(ItemCount)deviceIndex
                                     entity:(ItemCount)entityIndex

{
    MIDIEndpointRef dstPoint;
    
    MIDIDeviceRef devRef = MIDIGetDevice(deviceIndex);
    MIDIEntityRef devEty = MIDIDeviceGetEntity(devRef, entityIndex);
    dstPoint = MIDIEntityGetDestination(devEty, 0);
    return dstPoint;
}

@end
