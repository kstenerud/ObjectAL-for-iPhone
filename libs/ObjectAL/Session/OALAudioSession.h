//
//  OALAudioSession.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-12-19.
//
// Copyright 2010 Karl Stenerud
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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SynthesizeSingleton.h"
#import "OALSuspendHandler.h"


/**
 * Handles the audio session and interrupts.
 */
@interface OALAudioSession : NSObject <AVAudioSessionDelegate, OALSuspendManager>
{
    /** The current audio session category */
	NSString* audioSessionCategory;
	
	bool handleInterruptions;
	bool allowIpod;
	bool ipodDucking;
	bool useHardwareIfAvailable;
	bool honorSilentSwitch;
	
	bool audioSessionActive;
	
	id<AVAudioSessionDelegate> audioSessionDelegate;
	
	/** If true, the audio session was active when the interrupt occurred. */
	bool audioSessionWasActive;
	
	/** Handles suspending and interrupting for this object. */
	OALSuspendHandler* suspendHandler;
	
	/** Marks the last time the audio session was reset due to error.
	 * This is used to avoid getting stuck in a rapid-fire reset-error loop.
	 */
	NSDate* lastResetTime;
}



#pragma mark Properties

/** The current audio session category.
 * If this value is explicitly set, the other session properties "allowIpod",
 * "useHardwareIfAvailable", "honorSilentSwitch", and "ipodDucking" may be modified
 * to remain compatible with the category.
 *
 * @see AVAudioSessionCategory
 *
 * Default value: nil
 */
@property(readwrite,retain) NSString* audioSessionCategory;

/** If YES, allow ipod music to continue playing (NOT SUPPORTED ON THE SIMULATOR).
 * Note: If this is enabled, and another app is playing music, background audio
 * playback will use the SOFTWARE codecs, NOT hardware. <br>
 *
 * If allowIpod = NO, the application will ALWAYS use hardware decoding. <br>
 *
 * @see useHardwareIfAvailable
 *
 * Default value: YES
 */
@property(readwrite,assign) bool allowIpod;

/** If YES, ipod music will duck (lower in volume) when the audio session activates.
 *
 * Default value: NO
 */
@property(readwrite,assign) bool ipodDucking;

/** Determines what to do if no other application is playing audio and allowIpod = YES
 * (NOT SUPPORTED ON THE SIMULATOR). <br>
 *
 * If NO, the application will ALWAYS use software decoding. The advantage to this is that
 * the user can background your application and then start audio playing from another
 * application. If useHardwareIfAvailable = YES, the user won't be able to do this. <br>
 *
 * If this is set to YES, the application will use hardware decoding if no other application
 * is currently playing audio. However, no other application will be able to start playing
 * audio if it wasn't playing already. <br>
 *
 * Note: This switch has no effect if allowIpod = NO. <br>
 *
 * @see allowIpod
 *
 * Default value: YES
 */
@property(readwrite,assign) bool useHardwareIfAvailable;

/** If true, mute when backgrounded, screen locked, or the ringer switch is
 * turned off (NOT SUPPORTED ON THE SIMULATOR). <br>
 *
 * Default value: YES
 */
@property(readwrite,assign) bool honorSilentSwitch;

/** If true, automatically handle interruptions. <br>
 *
 * Default value: YES
 */
@property(readwrite,assign) bool handleInterruptions;

/** Delegate that will receive all audio session events.
 */
@property(readwrite,assign) id<AVAudioSessionDelegate> audioSessionDelegate;

/** If true, another application (usually iPod) is playing music. */
@property(readonly) bool ipodPlaying;

/** If true, the audio session is active */
@property(readwrite,assign) bool audioSessionActive;

/** Get the device's final hardware output volume, as controlled by
 * the volume button on the side of the device.
 */
@property(readonly) float hardwareVolume;

/** Check if the hardware mute switch is on (not supported on the simulator).
 * Note: If headphones are plugged in, hardwareMuted will always return FALSE
 *       regardless of the switch state.
 */
@property(readonly) bool hardwareMuted;

/** Check what hardware route the audio is taking, such as "Speaker" or "Headphone"
 * (not supported on the simulator).
 */
@property(readonly) NSString* audioRoute;


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (OALAudioSupport*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OALAudioSession);

/** Close any OS resources in use by this object.
 * This will close the audio session.
 */
- (void) close;


#pragma mark Utility

/** Force an interrupt end. This can be useful in cases where a buggy OS
 * fails to end an interrupt.
 *
 * Be VERY CAREFUL when using this!
 */
- (void) forceEndInterruption;

@end
