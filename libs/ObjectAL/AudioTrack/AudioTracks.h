//
//  AudioTracks.h
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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "AudioTrack.h"
#import "SynthesizeSingleton.h"


#pragma mark AudioTracks

/**
 * Keeps track of all AudioTrack objects.
 */
@interface AudioTracks : NSObject
{
	/** All instantiated audio tracks. */
	NSMutableArray* tracks;
	bool suspended;
	bool muted;
	bool paused;
}

#pragma mark Properties

/** Suspends/resumes all audio tracks. */
@property(readwrite,assign) bool suspended;

/** Pauses/unpauses all audio tracks. */
@property(readwrite,assign) bool paused;

/** Mutes/unmutes all audio tracks. */
@property(readwrite,assign) bool muted;

/** All instantiated audio tracks. */
@property(readonly) NSArray* tracks;


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (BackgroundAudio*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(AudioTracks);


#pragma mark Internal Use

/** (INTERNAL USE) Notify that a track is initializing.
 */
- (void) notifyTrackInitializing:(AudioTrack*) track;

/** (INTERNAL USE) Notify that a track is deallocating.
 */
- (void) notifyTrackDeallocating:(AudioTrack*) track;

@end
