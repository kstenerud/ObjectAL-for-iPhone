//
//  OALAudioTracks.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-18.
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

#import "OALAudioTrack.h"
#import "SynthesizeSingleton.h"
#import "OALSuspendHandler.h"


#pragma mark OALAudioTracks

/**
 * Keeps track of all AudioTrack objects.
 */
@interface OALAudioTracks : NSObject <OALSuspendManager>
{
	/** All instantiated audio tracks. */
	NSMutableArray* tracks;
	bool muted;
	bool paused;
    
    /** Timer to poll deviceCurrentTime so that it doesn't get reset on a device */
    NSTimer* deviceTimePoller;
	
	/** Handles suspending and interrupting for this object. */
	OALSuspendHandler* suspendHandler;
}

#pragma mark Properties

/** Pauses/unpauses all audio tracks. */
@property(readwrite,assign) bool paused;

/** Mutes/unmutes all audio tracks. */
@property(readwrite,assign) bool muted;

/** All instantiated audio tracks. */
@property(readonly) NSArray* tracks;


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (OALAudioTracks*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OALAudioTracks);

/** Close any OS resources in use by this object.
 * Any operations called on this object after closing will likely fail.
 */
- (void) close;


#pragma mark Internal Use

/** (INTERNAL USE) Notify that a track is initializing.
 */
- (void) notifyTrackInitializing:(OALAudioTrack*) track;

/** (INTERNAL USE) Notify that a track is deallocating.
 */
- (void) notifyTrackDeallocating:(OALAudioTrack*) track;

@end
