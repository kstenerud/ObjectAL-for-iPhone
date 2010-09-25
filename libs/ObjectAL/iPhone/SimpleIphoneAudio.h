//
//  SimpleAudio.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-01-14.
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
#import "ALDevice.h"
#import "ALContext.h"
#import "SoundSource.h"
#import "ChannelSource.h"
#import "AudioTrack.h"


#pragma mark SimpleIphoneAudio

/**
 * Very simple and basic interface to the iPhone sound system.
 *
 * Essentially, it initializes ObjectAL with the default device,
 * a context, and a channel consisting of 32 interruptible sources.
 *
 * It also accesses IphoneAudioSupport to turn on automatic interrupt handling.
 *
 * All commands are delegated either to the channel (for sound effects),
 * or to BackgroundAudio (for BG music).
 */
@interface SimpleIphoneAudio : NSObject
{
	/** The device we are using */
	ALDevice* device;
	/** The context we are using */
	ALContext* context;

	/** The sound channel used by this object. */
	ChannelSource* channel;
	/** Cache for preloaded sound samples. */
	NSMutableDictionary* preloadCache;

	/** Audio track to play background music */
	AudioTrack* backgroundTrack;
	
	bool muted;
	bool bgMuted;
	bool effectsMuted;
}


#pragma mark Properties

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

/** Determines what to do if no other application is playing audio and allowIpod = YES
 * (NOT SUPPORTED ON THE SIMULATOR). <br>
 *
 * If NO, the application will ALWAYS use software decoding.  The advantage to this is that
 * the user can background your application and then start audio playing from another
 * application.  If useHardwareIfAvailable = YES, the user won't be able to do this. <br>
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

/** Background audio track */
@property(readonly) AudioTrack* backgroundTrack;

/** Pauses BG music playback */
@property(readwrite,assign) bool bgPaused;

/** Mutes BG music playback */
@property(readwrite,assign) bool bgMuted;

/** If true, BG music is currently playing */
@property(readonly) bool bgPlaying;

/** Background music playback gain/volume (0.0 - 1.0) */
@property(readwrite,assign) float bgVolume;

/** Pauses effects playback */
@property(readwrite,assign) bool effectsPaused;

/** Mutes effects playback */
@property(readwrite,assign) bool effectsMuted;

/** Master effects gain/volume (0.0 - 1.0) */
@property(readwrite,assign) float effectsVolume;

/** Pauses everything */
@property(readwrite,assign) bool paused;

/** Mutes all audio */
@property(readwrite,assign) bool muted;

/** Enables/disables the preload cache.
 * If the preload cache is disabled, effects preloading will do nothing (BG preloading will still
 * work).
 */
@property(readwrite,assign) bool preloadCacheEnabled;

/** The number of items currently in the preload cache. */
@property(readonly) NSUInteger preloadCacheCount;

#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (SimpleIphoneAudio*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance. <br>
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(SimpleIphoneAudio);

/** Start SimpleIphoneAudio with the specified number of reserved sources.
 * Call this initializer if you want to use SimpleIphoneAudio, but keep some of the iPhone's
 * audio sources (there are 32 in total) for your own use. <br>
 * <strong>Note:</strong> This method must be called ONLY ONCE, <em>BEFORE</em>
 * any attempt is made to access the shared instance.
 *
 * @param sources the number of sources SimpleIphoneAudio will reserve for itself.
 * @return The shared instance.
 */
+ (SimpleIphoneAudio*) sharedInstanceWithSources:(int) sources;

/** (INTERNAL USE) Initialize with the specified number of reserved sources.
 *
 * @param sources the number of sources to reserve when initializing.
 * @return The shared instance.
 */
- (id) initWithSources:(int) sources;


#pragma mark Background Music

/** Preload background music.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> background music
 * file may be played or preloaded at a time (the hardware only supports one
 * file at a time). If you play or preload another file, the one currently playing
 * will stop.
 *
 * @param path The path containing the background music.
 * @return TRUE if the operation was successful.
 */
- (bool) preloadBg:(NSString*) path;

/** Play whatever background music is preloaded.
 *
 * @return TRUE if the operation was successful.
 */
- (bool) playBg;

/** Play whatever background music is preloaded.
 *
 * @param loop If true, loop the bg track.
 * @return TRUE if the operation was successful.
 */
- (bool) playBgWithLoop:(bool) loop;

/** Play the background music at the specified path.
 * If the music has not been preloaded, this method
 * will load the music and then play, incurring a slight delay. <br>
 *
 * <strong>Note:</strong> only <strong>ONE</strong> background music
 * file may be played or preloaded at a time (the hardware only supports one
 * file at a time). If you play or preload another file, the one currently playing
 * will stop.
 *
 * @param path The path containing the background music.
 * @return TRUE if the operation was successful.
 */
- (bool) playBg:(NSString*) path;

/** Play the background music at the specified path.
 * If the music has not been preloaded, this method
 * will load the music and then play, incurring a slight delay. <br>
 *
 * <strong>Note:</strong> only <strong>ONE</strong> background music
 * file may be played or preloaded at a time (the hardware only supports one
 * file at a time). If you play or preload another file, the one currently playing
 * will stop.
 *
 * @param path The path containing the background music.
 * @param loop If true, loop the bg track.
 * @return TRUE if the operation was successful.
 */
- (bool) playBg:(NSString*) path loop:(bool) loop;

/** Stop the background music playback and rewind.
 */
- (void) stopBg;


#pragma mark Sound Effects

/** Preload and cache a sound effect for later playback.
 *
 * @param filePath The path containing the sound data.
 */
- (void) preloadEffect:(NSString*) filePath;

/** Unload a preloaded effect.
 *
 * @param filePath The path containing the sound data that was previously loaded.
 */
- (void) unloadEffect:(NSString*) filePath;

/** Unload all preloaded effects.
 * It is useful to put a call to this method in
 * "applicationDidReceiveMemoryWarning" in your app delegate.
 */
- (void) unloadAllEffects;

/** Play a sound effect with volume 1.0, pitch 1.0, pan 0.0, loop NO.  The sound will be loaded
 * and cached if it wasn't already.
 *
 * @param filePath The path containing the sound data.
 * @return The sound source being used for playback, or nil if an error occurred.
 */
- (id<SoundSource>) playEffect:(NSString*) filePath;

/** Play a sound effect with volume 1.0, pitch 1.0, pan 0.0.  The sound will be loaded and cached
 * if it wasn't already.
 *
 * @param filePath The path containing the sound data.
 * @param loop If TRUE, the sound will loop until you call "stop" on the returned sound source.
 * @return The sound source being used for playback, or nil if an error occurred.
 */
- (id<SoundSource>) playEffect:(NSString*) filePath loop:(bool) loop;

/** Play a sound effect.  The sound will be loaded and cached if it wasn't already.
 *
 * @param filePath The path containing the sound data.
 * @param volume The volume (gain) to play at (0.0 - 1.0).
 * @param pitch The pitch to play at (1.0 = normal pitch).
 * @param pan Left-right panning (-1.0 = far left, 1.0 = far right).
 * @param loop If TRUE, the sound will loop until you call "stop" on the returned sound source.
 * @return The sound source being used for playback, or nil if an error occurred (You'll need to
 *         keep this if you want to be able to stop a looped playback).
 */
- (id<SoundSource>) playEffect:(NSString*) filePath
						volume:(float) volume
						 pitch:(float) pitch
						   pan:(float) pan
						  loop:(bool) loop;

/** Stop ALL sound effect playback.
 */
- (void) stopAllEffects;


#pragma mark Utility

/** Stop all effects and bg music.
 */
- (void) stopEverything;

@end
