//
//  OpenALManager.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-25.
//
// Copyright 2009 Karl Stenerud
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Note: You are NOT required to make the license available from within your
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "ALContext.h"
#import "ALDevice.h"


#pragma mark OpenALManager

/**
 * Master class for the ObjectAL library.
 * Keeps track of devices that have been opened, and allows high level OpenAL management. <br>
 * The OpenAL 1.1 specification is available at
 * http://connect.creativelabs.com/openal/Documentation <br>
 * Be sure to read through it (especially the part about distance models) as ObjectAL follows the
 * OpenAL object model.
 * Alternatively, you may opt to use SimpleIphoneAudio for your audio needs.
 */
@interface OpenALManager : NSObject
{
	ALContext* currentContext; // WEAK reference
	
	/** All opened devices */
	NSMutableArray* devices;
	
	/** All suspended contexts */
	NSMutableArray* suspendedContexts;
	
	bool suspended;
}


#pragma mark Properties

/** List of available playback devices (NSString*). */
@property(readonly) NSArray* availableDevices;

/** List of available capture devices (NSString*). */
@property(readonly) NSArray* availableCaptureDevices;

/** The current context (some context operations require the context to be the "current" one). */
@property(readwrite,assign) ALContext* currentContext;

/** Name of the default capture device. */
@property(readonly) NSString* defaultCaptureDeviceSpecifier;

/** Name of the default playback device. */
@property(readonly) NSString* defaultDeviceSpecifier;

/** List of all open devices (ALDevice*). */
@property(readonly) NSArray* devices;

/** The frequency of the output mixer. */
@property(readwrite,assign) ALdouble mixerOutputFrequency;


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (ObjectAL*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OpenALManager);


#pragma mark Utility

/** Clear all references to sound data from ALL buffers, managed or not.
 */
- (void) clearAllBuffers;


#pragma mark Internal Use

/** (INTERNAL USE) Used by the interrupt handler to suspend ObjectAL
 * (if interrupts are enabled in IphoneAudioSupport).
 */
@property(readwrite,assign) bool suspended;

/** (INTERNAL USE) Notify that a device is initializing.
 */
- (void) notifyDeviceInitializing:(ALDevice*) device;

/** (INTERNAL USE) Notify that a device is deallocating.
 */
- (void) notifyDeviceDeallocating:(ALDevice*) device;

@end
