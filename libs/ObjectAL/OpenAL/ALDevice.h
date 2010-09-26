//
//  ALDevice.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-01-09.
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
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import "ALContext.h"


#pragma mark ALDevice

/**
 * A device is a logical mapping to an audio device through the OpenAL implementation.
 */
@interface ALDevice : NSObject
{
	ALCdevice* device;
	/** All contexts opened from this device. */
	NSMutableArray* contexts;
}


#pragma mark Properties

/** All contexts created on this device (ALContext*). */
@property(readonly) NSArray* contexts;

/** The OpenAL device pointer. */
@property(readonly) ALCdevice* device;

/** List of strings describing all extensions available on this device (NSString*). */
@property(readonly) NSArray* extensions;

/** The specification revision for this implementation (major version). */
@property(readonly) int majorVersion;

/** The specification revision for this implementation (minor version). */
@property(readonly) int minorVersion;


#pragma mark Object Management

/** Open the specified device.
 *
 * @param deviceSpecifier The device to open (nil = default device).
 * @return A new device.
 */
+ (id) deviceWithDeviceSpecifier:(NSString*) deviceSpecifier;

/** Initialize with the specified device.
 *
 * @param deviceSpecifier The device to open (nil = default device).
 * @return the initialized device.
 */
- (id) initWithDeviceSpecifier:(NSString*) deviceSpecifier;


#pragma mark Extensions

/** Check if the specified extension is present.
 *
 * @param name The extension to check.
 * @return TRUE if the extension is present.
 */
- (bool) isExtensionPresent:(NSString*) name;

/** Get the address of the specified procedure (C function address).
 *
 * @param functionName the name of the procedure to get.
 * @return the procedure's address, or NULL if it wasn't found.
 */
- (void*) getProcAddress:(NSString*) functionName;


#pragma mark Utility

/** Clear all buffers being used by sources of contexts opened on this device.
 */
- (void) clearBuffers;


#pragma mark Internal Use

/** (INTERNAL USE)  Used by ALContext to announce initialization.
 *
 * @param context The context that is initializing.
 */
- (void) notifyContextInitializing:(ALContext*) context;

/** (INTERNAL USE)  Used by ALContext to announce deallocation.
 *
 * @param context The context that is deallocating.
 */
- (void) notifyContextDeallocating:(ALContext*) context;

@end
