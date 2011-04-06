//
//  OALSimpleAudio.h
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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "ALDevice.h"
#import "ALContext.h"
#import "ALSoundSource.h"
#import "ALChannelSource.h"
#import "OALAudioTrack.h"


#pragma mark OALSimpleAudio

/**
 * A simpler interface to the ObjectAL sound library. This singleton can be
 * used alone for simpler audio needs, or in conjunction with user-created
 * audio objects for more advanced needs (as is done in many of the demos).
 *
 * For sound effects, it initializes OpenAL with the default ALDevice,
 * an ALContext, and an ALChannelSource consisting of all 32 interruptible
 * ALSource objects (the maximum currently allowed for iOS).
 * If you want to create your own sources as well, change the reservedSources
 * property.
 *
 * For background audio, it creates a single OALAudioTrack, which will not reserve
 * resources unless used. (you can create more OALAudioTrack objects for your own
 * use if you want).
 *
 * This singleton also provides access to the more common configuration options
 * available in OALAudioSupport.
 *
 * All audio playback commands are delegated either to the ALChannelSource
 * (for sound effects), or to the OALAudioTrack (for BG music).
 */
@interface OALSimpleAudio : NSObject
{
	/** The device we are using */
	ALDevice* device;
	/** The context we are using */
	ALContext* context;

	/** The sound channel used by this object. */
	ALChannelSource* channel;
	/** Cache for preloaded sound samples. */
	NSMutableDictionary* preloadCache;
#if NS_BLOCKS_AVAILABLE && OBJECTAL_USE_BLOCKS
	/** Queue for preloading and async operations that use blocks.
	 * This ensures all operations are safe because they are guaranteed to run
	 * in order.
	 */
	dispatch_queue_t oal_dispatch_queue;
#endif
	/** keeping track of how many effects remain to be loaded */
	uint pendingLoadCount;
	
	/** Audio track to play background music */
	OALAudioTrack* backgroundTrack;
	
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

/** The number of sources OALSimpleAudio is using (max 32 on current iOS devices). */
@property(readwrite,assign) unsigned int reservedSources;

/** The channel source used by OALSimpleAudio.
 * Only mess with this if you know what you are doing!
 */
@property(readonly) ALChannelSource* channel;

/** Background audio URL */
@property(readonly) NSURL* backgroundTrackURL;

/** Background audio track */
@property(readonly) OALAudioTrack* backgroundTrack;

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
 * If the preload cache is disabled, effects preloading will do nothing
 * (BG preloading will still work).
 */
@property(readwrite,assign) bool preloadCacheEnabled;

/** The number of items currently in the preload cache. */
@property(readonly) NSUInteger preloadCacheCount;

/** Set to YES to manually suspend the sound system. */
@property(readwrite,assign) bool manuallySuspended;

/** If YES, the sound system is interrupted. */
@property(readonly) bool interrupted;

/** If YES, the sound system is suspended. */
@property(readonly) bool suspended;



#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (OALSimpleAudio*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance. <br>
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OALSimpleAudio);

/** Start OALSimpleAudio with the specified number of reserved sources.
 * Call this initializer if you want to use OALSimpleAudio, but keep some of the device's
 * audio sources (there are 32 in total) for your own use. <br>
 * <strong>Note:</strong> This method must be called ONLY ONCE, <em>BEFORE</em>
 * any attempt is made to access the shared instance.
 * To change the reserved sources after instantiation, modify reservedSources.
 *
 * @param sources the number of sources OALSimpleAudio will reserve for itself.
 * @return The shared instance.
 */
+ (OALSimpleAudio*) sharedInstanceWithSources:(int) sources;

/** (INTERNAL USE) Initialize with the specified number of reserved sources.
 *
 * @param sources the number of sources to reserve when initializing.
 * @return The shared instance.
 */
- (id) initWithSources:(int) sources;

/** Close any OS resources in use by this object.
 * Any operations called on this object after closing will likely fail.
 */
- (void) close;


#pragma mark Background Music

/** Preload background music.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> background music
 * file may be played or preloaded at a time via OALSimpleAudio.
 * If you play or preload another file, the one currently playing
 * will stop.
 *
 * @param path The path containing the background music.
 * @return TRUE if the operation was successful.
 */
- (bool) preloadBg:(NSString*) path;

/** Preload background music.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> background music
 * file may be played or preloaded at a time via OALSimpleAudio.
 * If you play or preload another file, the one currently playing
 * will stop.
 *
 * @param path The path containing the background music.
 * @param seekTime the position in the file to start playing at.
 * @return TRUE if the operation was successful.
 */
- (bool) preloadBg:(NSString*) path seekTime:(NSTimeInterval)seekTime;

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
 * file may be played or preloaded at a time via OALSimpleAudio.
 * If you play or preload another file, the one currently playing
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
 * file may be played or preloaded at a time via OALSimpleAudio.
 * If you play or preload another file, the one currently playing
 * will stop.
 *
 * @param path The path containing the background music.
 * @param loop If true, loop the bg track.
 * @return TRUE if the operation was successful.
 */
- (bool) playBg:(NSString*) path loop:(bool) loop;

/** Play the background music at the specified path.
 * If the music has not been preloaded, this method
 * will load the music and then play, incurring a slight delay. <br>
 *
 * <strong>Note:</strong> only <strong>ONE</strong> background music
 * file may be played or preloaded at a time via OALSimpleAudio.
 * If you play or preload another file, the one currently playing
 * will stop. To play multiple audio tracks, create an OALAudioTrack. <br>
 *
 * <strong>Note:</strong> pan will have no effect when running on iOS
 * versions prior to 4.0.
 *
 * @param filePath The path containing the sound data.
 * @param volume The volume (gain) to play at (0.0 - 1.0).
 * @param pan Left-right panning (-1.0 = far left, 1.0 = far right) (Only on iOS 4.0+).
 * @param loop If TRUE, the sound will loop until you call "stopBg".
 * @return TRUE if the operation was successful.
 */
- (bool) playBg:(NSString*) filePath
		 volume:(float) volume
			pan:(float) pan
		   loop:(bool) loop;

/** Stop the background music playback and rewind.
 */
- (void) stopBg;


#pragma mark Sound Effects

/** Preload and cache a sound effect for later playback.
 *
 * @param filePath The path containing the sound data.
 */
- (ALBuffer*) preloadEffect:(NSString*) filePath;

/** Preload and cache a sound effect for later playback.
 *
 * @param filePath The path containing the sound data.
 * @param reduceToMono If true, reduce the sample to mono
 *        (stereo samples don't support panning or positional audio).
 */
- (ALBuffer*) preloadEffect:(NSString*) filePath reduceToMono:(bool) reduceToMono;

#if NS_BLOCKS_AVAILABLE && OBJECTAL_USE_BLOCKS

/** Asynchronous preload and cache sound effect for later playback.
 *
 * @param filePath an NSString with the path containing the sound data.
 * @param reduceToMono If true, reduce the sample to mono
 *        (stereo samples don't support panning or positional audio).
 * @param completionBlock Executed when loading is complete.
 */
- (BOOL) preloadEffect:(NSString*) filePath
				  reduceToMono:(bool) reduceToMono
	   completionBlock:(void(^)(ALBuffer *)) completionBlock;

/** Asynchronous preload and cache multiple sound effects for later playback.
 *
 * @param filePaths An NSArray of NSStrings with the paths containing the sound data.
 * @param reduceToMono If true, reduce the samples to mono
 *        (stereo samples don't support panning or positional audio).
 * @param progressBlock Executed regularly while file loading is in progress.
 */
- (void) preloadEffects:(NSArray*) filePaths
				   reduceToMono:(bool) reduceToMono
		  progressBlock:(void (^)(uint progress, uint successCount, uint total)) progressBlock;

#endif

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

/** Play a sound effect with volume 1.0, pitch 1.0, pan 0.0, loop NO. The sound will be loaded
 * and cached if it wasn't already.
 *
 * @param filePath The path containing the sound data.
 * @return The sound source being used for playback, or nil if an error occurred.
 */
- (id<ALSoundSource>) playEffect:(NSString*) filePath;

/** Play a sound effect with volume 1.0, pitch 1.0, pan 0.0. The sound will be loaded and cached
 * if it wasn't already.
 *
 * @param filePath The path containing the sound data.
 * @param loop If TRUE, the sound will loop until you call "stop" on the returned sound source.
 * @return The sound source being used for playback, or nil if an error occurred.
 */
- (id<ALSoundSource>) playEffect:(NSString*) filePath loop:(bool) loop;

/** Play a sound effect. The sound will be loaded and cached if it wasn't already.
 *
 * @param filePath The path containing the sound data.
 * @param volume The volume (gain) to play at (0.0 - 1.0).
 * @param pitch The pitch to play at (1.0 = normal pitch).
 * @param pan Left-right panning (-1.0 = far left, 1.0 = far right).
 * @param loop If TRUE, the sound will loop until you call "stop" on the returned sound source.
 * @return The sound source being used for playback, or nil if an error occurred (You'll need to
 *         keep this if you want to be able to stop a looped playback).
 */
- (id<ALSoundSource>) playEffect:(NSString*) filePath
						volume:(float) volume
						 pitch:(float) pitch
						   pan:(float) pan
						  loop:(bool) loop;

/** Play a sound effect from a user-supplied buffer.
 *
 * @param buffer The buffer containing the sound data.
 * @param volume The volume (gain) to play at (0.0 - 1.0).
 * @param pitch The pitch to play at (1.0 = normal pitch).
 * @param pan Left-right panning (-1.0 = far left, 1.0 = far right).
 * @param loop If TRUE, the sound will loop until you call "stop" on the returned sound source.
 * @return The sound source being used for playback, or nil if an error occurred (You'll need to
 *         keep this if you want to be able to stop a looped playback).
 */
- (id<ALSoundSource>) playBuffer:(ALBuffer*) buffer
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

/** Reset everything in this object to its default state.
 */
- (void) resetToDefault;

@end
