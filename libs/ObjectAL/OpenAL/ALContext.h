//
//  ALContext.h
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
#import "ALListener.h"
#import "ALSource.h"

@class ALDevice;


#pragma mark ALContext

/**
 * A context encompasses a single listener and a series of sources.
 * A context is created from a device, and many contexts may be created
 * (though multiple contexts would be unusual in an iPhone app). <br>
 *
 * Note: Some property values are only valid if this context is the current
 * context.
 *
 * @see ObjectAL.currentContext
 */
@interface ALContext : NSObject
{
	ALCcontext* context;
	ALDevice* device;
	/** All sound sources associated with this context. */
	NSMutableArray* sources;
	ALListener* listener;
	bool suspended;
	/** This context's attributes. */
	NSMutableArray* attributes;
}


#pragma mark Properties

/** OpenAL version string in format
 * “[spec major number].[spec minor number] [optional vendor version information]”
 * Only valid when this is the current context.
 */
@property(readonly) NSString* alVersion;

/** The current context's attribute list.
 * Only valid when this is the current context.
 */
@property(readonly) NSArray* attributes;

/** The OpenAL context pointer. */
@property(readonly) ALCcontext* context;

/** The device this context was opened on. */
@property(readonly) ALDevice* device;

/** The current distance model.
 * Legal values are AL_NONE, AL_INVERSE_DISTANCE, AL_INVERSE_DISTANCE_CLAMPED,
 * AL_LINEAR_DISTANCE, AL_LINEAR_DISTANCE_CLAMPED, AL_EXPONENT_DISTANCE,
 * and AL_EXPONENT_DISTANCE_CLAMPED.  See the OpenAL spec for detailed information. <br>
 * Only valid when this is the current context.
 */
@property(readwrite,assign) ALenum distanceModel;

/** Exaggeration factor for Doppler effect.
 * Only valid when this is the current context.
 */
@property(readwrite,assign) float dopplerFactor;

/** List of available extensions (NSString*).
 * Only valid when this is the current context.
 */
@property(readonly) NSArray* extensions;

/** This context's listener. */
@property(readonly) ALListener* listener;

/** Information about the specific renderer.
 * Only valid when this is the current context.
 */
@property(readonly) NSString* renderer;

/** All sources associated with this context (ALSource*). */
@property(readonly) NSArray* sources;

/** Speed of sound in same units as velocities.
 * Only valid when this is the current context.
 */
@property(readwrite,assign) float speedOfSound;

/** If true, this context is suspended. */
@property(readwrite,assign) bool suspended;

/** Name of the vendor.
 * Only valid when this is the current context.
 */
@property(readonly) NSString* vendor;


#pragma mark Object Management

/** Create a new context on the specified device.
 *
 * @param device The device to open the context on.
 * @param attributes An array of NSNumber in ordered pairs (attribute id followed by integer value).
 * Posible attributes: ALC_FREQUENCY, ALC_REFRESH, ALC_SYNC, ALC_MONO_SOURCES, ALC_STEREO_SOURCES
 * @return A new context.
 */
+ (id) contextOnDevice:(ALDevice *) device attributes:(NSArray*) attributes;

/** Create a new context on the specified device with attributes.
 *
 * @param device The device to open the context on.
 * @param outputFrequency The frequency to mix all sources to before outputting.
 * @param refreshIntervals The number of passes per second used to mix the audio sources.
 *        For games this can be 5-15.  For audio intensive apps, it should be higher.
 * @param synchronousContext If true, this context runs on the main thread and depends on you
 *        calling alcUpdateContext (best to leave this FALSE unless you know what you're doing).
 * @param monoSources A hint indicating how many sources should support mono.
 * @param stereoSources A hint indicating how many sources should support stereo.
 * @return A new context.
 */
+ (id) contextOnDevice:(ALDevice*) device
	   outputFrequency:(int) outputFrequency
	  refreshIntervals:(int) refreshIntervals 
	synchronousContext:(bool) synchronousContext
		   monoSources:(int) monoSources
		 stereoSources:(int) stereoSources;


/** Initialize this context on the specified device with attributes.
 *
 * @param device The device to open the context on.
 * @param outputFrequency The frequency to mix all sources to before outputting.
 * @param refreshIntervals The number of passes per second used to mix the audio sources.
 *        For games this can be 5-15.  For audio intensive apps, it should be higher.
 * @param synchronousContext If true, this context runs on the main thread and depends on you
 *        calling alcUpdateContext (best to leave this FALSE unless you know what you're doing).
 * @param monoSources A hint indicating how many sources should support mono.
 * @param stereoSources A hint indicating how many sources should support stereo.
 * @return The initialized context.
 */
- (id) initOnDevice:(ALDevice*) device
	outputFrequency:(int) outputFrequency
   refreshIntervals:(int) refreshIntervals 
 synchronousContext:(bool) synchronousContext
		monoSources:(int) monoSources
	  stereoSources:(int) stereoSources;


/** Initialize this context for the specified device and attributes.
 *
 * @param device The device to open the context on.
 * @param attributes An array of NSNumber in ordered pairs (attribute id followed by integer value).
 * Posible attributes: ALC_FREQUENCY, ALC_REFRESH, ALC_SYNC, ALC_MONO_SOURCES, ALC_STEREO_SOURCES
 * @return The initialized context.
 */
- (id) initOnDevice:(ALDevice *) device attributes:(NSArray*) attributes;


#pragma mark Utility

/** Process this context.
 */
- (void) process;

/** Stop all sound sources in this context.
 */
- (void) stopAllSounds;

/** Clear all buffers being used by sources in this context.
 */
- (void) clearBuffers;


#pragma mark Extensions

/** Check if the specified extension is present in this context.
 * Only valid when this is the current context.
 *
 * @param name The name of the extension to check.
 * @return TRUE if the extension is present in this context.
 */
- (bool) isExtensionPresent:(NSString*) name;

/** Get the address of the specified procedure (C function address).
 * Only valid when this is the current context. <br>
 * <strong>Note:</strong> The OpenAL implementation is free to return
 * a pointer even if it is not valid for this context.  Always call isExtensionPresent
 * first.
 *
 * @param functionName the name of the procedure to get.
 * @return the procedure's address, or NULL if it wasn't found.
 */
- (void*) getProcAddress:(NSString*) functionName;


#pragma mark Internal Use

/** (INTERNAL USE)  Used by ALSource to announce initialization.
 *
 * @param source the source that is initializing.
 */
- (void) notifySourceInitializing:(ALSource*) source;

/** (INTERNAL USE)  Used by ALSource to announce deallocation.
 *
 * @param source the source that is deallocating.
 */
- (void) notifySourceDeallocating:(ALSource*) source;

@end
