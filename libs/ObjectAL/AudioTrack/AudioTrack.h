//
//  AudioTrack.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-21.
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

#import <AVFoundation/AVFoundation.h>


/**
 * Plays an audio track via AVAudioPlayer.
 * Unlike AVAudioPlayer, however, it can be re-used to play another file.
 * Interruptions can be handled by IphoneAudioSupport (enabled by default).
 */
@interface AudioTrack : NSObject <AVAudioPlayerDelegate>
{
	bool meteringEnabled;
	bool suspended;
	AVAudioPlayer* player;
	NSURL* currentlyLoadedUrl;
	bool paused;
	bool muted;
	float gain;
	NSInteger numberOfLoops;
	id<AVAudioPlayerDelegate> delegate; // Weak reference
	
	/** When the simulator is running (and the playback fix is in use),
	 * player will be copied to here, and then player set to nil.
	 * This prevents other code from inadvertently raising the volume
	 * and starting playback.
	 */
	AVAudioPlayer* simulatorPlayerRef;
	
	/** Operation queue for running asynchronous operations.
	 * Note: Only one asynchronous operation is allowed at a time.
	 */
	NSOperationQueue* operationQueue;
	
	/** If true, the audio player is currently playing.
	 * We need to maintain our own value because AVAudioPlayer will
	 * sometimes say it's not playing when it actually is.
	 */
	bool playing;
	
	/** Target to inform when the current fade operation completes. */
	id fadeCompleteTarget;
	
	/** Selector to call when the current fade operation completes. */
	SEL fadeCompleteSelector;
	
	/** The gain we started this fade from. */
	float fadeStartingGain;
	
	/** The gain we are fading to. */
	float fadeEndingGain;
	
	/** The duration of the fade operation. */
	float fadeDuration;
	
	/** A multiplier applied to the elapsed time to give a fade delta. */
	float fadeDeltaMultiplier;
	
	/** The time that this fade operation started. */
	uint64_t fadeStartTime;
	
	/** The timer corrdinating the fade operation. */
	NSTimer* fadeTimer;
}


#pragma mark Properties

/** The URL of the currently loaded audio data. */
@property(readonly) NSURL* currentlyLoadedUrl;

/** Optional object that will receive notifications for decoding errors,
 * audio interruptions (such as an incoming phone call), and playback completion. <br>
 * Note: BackgroundAudio keeps a WEAK reference to delegate, so make sure you clear it
 * when your object is going to be deallocated.
 */
@property(readwrite,assign) id<AVAudioPlayerDelegate> delegate;

/** The gain (volume) for playback (0.0 - 1.0, where 1.0 = no attenuation). */
@property(readwrite,assign) float gain;

/** If true, background audio is muted */
@property(readwrite,assign) bool muted;

/** The number of times to loop playback (-1 = forever).
 * Note: This value will be ignored, and get changed when you call the various playXX methods.
 * Only [[BackgroundAudio sharedInstance] play] will use the current value of "numberOfLoops".
 */
@property(readwrite,assign) NSInteger numberOfLoops;

/** If true, pause playback. */
@property(readwrite,assign) bool paused;

/** Access to the underlying AVAudioPlayer object.
 * WARNING: Be VERY careful when accessing this.  Modifying anything will
 * likely cause it to fall out of sync with BackgroundAudio.
 */
@property(readonly) AVAudioPlayer* player;

/** If true, background music is currently playing. */
@property(readonly) bool playing;

/** The current playback position in seconds from the start of the sound.
 * You can set this to change the playback position, whether it is currently playing or not.
 */
@property(readwrite,assign) NSTimeInterval currentTime;

/** The duration, in seconds, of the currently loaded sound. */
@property(readonly) NSTimeInterval duration;

/** The number of channels in the currently loaded sound. */
@property(readonly) NSUInteger numberOfChannels;


#pragma mark Object Management

/** Create a new audio track.
 *
 * @return A new audio track.
 */
+ (id) track;


#pragma mark Playback

/** Preload the contents of a URL for playback.
 * Once the audio data is preloaded, you can call "play" to play it. <br>
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param url The URL containing the sound data.
 * @return TRUE if the operation was successful.
 */
- (bool) preloadUrl:(NSURL*) url;

/** Preload the contents of a file for playback.
 * Once the audio data is preloaded, you can call "play" to play it. <br>
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param path The file containing the sound data.
 * @return TRUE if the operation was successful.
 */
- (bool) preloadFile:(NSString*) path;

/** Asynchronously preload the contents of a URL for playback.
 * Once the audio data is preloaded, you can call "play" to play it. <br>
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param url The URL containing the sound data.
 * @param target the target to inform when preparation is complete.
 * @param selector the selector to call when preparation is complete.
 * @return TRUE if the operation was successfully queued.
 */
- (bool) preloadUrlAsync:(NSURL*) url target:(id) target selector:(SEL) selector;

/** Asynchronously preload the contents of a file for playback.
 * Once the audio data is preloaded, you can call "play" to play it. <br>
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param path The file containing the sound data.
 * @param target the target to inform when preparation is complete.
 * @param selector the selector to call when preparation is complete.
 * @return TRUE if the operation was successfully queued.
 */
- (bool) preloadFileAsync:(NSString*) path target:(id) target selector:(SEL) selector;

/** Play the contents of a URL once.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param url The URL containing the sound data.
 * @return TRUE if the operation was successful.
 */
- (bool) playUrl:(NSURL*) url;

/** Play the contents of a URL and loop the specified number of times.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param url The URL containing the sound data.
 * @param loops The number of times to loop playback (-1 = forever)
 * @return TRUE if the operation was successful.
 */
- (bool) playUrl:(NSURL*) url loops:(NSInteger) loops;

/** Play the contents of a file once.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param path The file containing the sound data.
 * @return TRUE if the operation was successful.
 */
- (bool) playFile:(NSString*) path;

/** Play the contents of a file and loop the specified number of times.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param path The file containing the sound data.
 * @param loops The number of times to loop playback (-1 = forever)
 * @return TRUE if the operation was successful.
 */
- (bool) playFile:(NSString*) path loops:(NSInteger) loops;

/** Play the contents of a URL asynchronously once.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param url The URL containing the sound data.
 * @param target the target to inform when playing has started.
 * @param selector the selector to call when playing has started.
 */
- (void) playUrlAsync:(NSURL*) url target:(id) target selector:(SEL) selector;

/** Play the contents of a URL asynchronously and loop the specified number of times.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param url The URL containing the sound data.
 * @param loops The number of times to loop playback (-1 = forever)
 * @param target the target to inform when playing has started.
 * @param selector the selector to call when playing has started.
 */
- (void) playUrlAsync:(NSURL*) url
				loops:(NSInteger) loops
			   target:(id) target
			 selector:(SEL) selector;

/** Play the contents of a file asynchronously once.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param path The file containing the sound data.
 * @param target the target to inform when playing has started.
 * @param selector the selector to call when playing has started.
 */
- (void) playFileAsync:(NSString*) path target:(id) target selector:(SEL) selector;

/** Play the contents of a file asynchronously and loop the specified number of times.
 *
 * <strong>Note:</strong> only <strong>ONE</strong> file may be played or
 * preloaded at a time (the hardware only supports one file at a time).
 * If you play or preload another file, the one currently playing will stop.
 *
 * @param path The file containing the sound data.
 * @param loops The number of times to loop playback (-1 = forever)
 * @param target the target to inform when playing has started.
 * @param selector the selector to call when playing has started.
 */
- (void) playFileAsync:(NSString*) path
				 loops:(NSInteger) loops
				target:(id) target
			  selector:(SEL) selector;

/** Play the currently loaded audio track.
 *
 * @return TRUE if the operation was successful.
 */
- (bool) play;

/** Stop playing and stop all operations.
 */
- (void) stop;

/** Fade to the specified gain value.
 *
 * Note: By default, fade operations are tuned for fade operations 0.2 seconds and above.  If you
 * need shorter fade durations, modify kBackgroundAudio_FadeInterval in ObjectALConfig.h.
 *
 * @param gain The gain to fade to.
 * @param duration The duration of the fade operation in seconds.
 * @param target The target to notify when the fade completes (can be nil).
 * @param selector The selector to call when the fade completes.  The selector must accept
 * a single parameter, which will be the object that performed the fade.
 */
- (void) fadeTo:(float) gain
	   duration:(float) duration
		 target:(id) target
	   selector:(SEL) selector;

/** Stop the currently running fade operation, if any.
 */
- (void) stopFade;

/** Unload and clear all audio data, stop playing, and stop all operations.
 */
- (void) clear;

#pragma mark Metering

/** If true, metering is enabled. */
@property (readwrite,assign) bool meteringEnabled;

/** Updates the metering system to give current values.
 * You must call this method before calling averagePowerForChannel or peakPowerForChannel in
 * order to get current values.
 */
- (void) updateMeters;

/** Gives the average power for a given channel, in decibels, for the sound being played.
 * 0 dB indicates maximum power (full scale). <br>
 * -160 dB indicates minimum power (near silence). <br>
 * If the signal provided to the audio player exceeds full scale, then the value may be > 0. <br>
 *
 * <strong>Note:</strong> The value returned is in reference to when updateMeters was last called.
 * You must call updateMeters again before calling this method to get a current value.
 *
 * @param channelNumber The channel to get the value from.  For mono or left, use 0.  For right,
 *        use 1.
 * @return the average power for the channel.
 */
- (float) averagePowerForChannel:(NSUInteger)channelNumber;

/** Gives the peak power for a given channel, in decibels, for the sound being played.
 * 0 dB indicates maximum power (full scale). <br>
 * -160 dB indicates minimum power (near silence). <br>
 * If the signal provided to the audio player exceeds full scale, then the value may be > 0. <br>
 *
 * <strong>Note:</strong> The value returned is in reference to when updateMeters was last called.
 * You must call updateMeters again before calling this method to get a current value.
 *
 * @param channelNumber The channel to get the value from.  For mono or left, use 0.  For right,
 *        use 1.
 * @return the average power for the channel.
 */
- (float) peakPowerForChannel:(NSUInteger)channelNumber;


#pragma mark Internal Use

/** (INTERNAL USE) Used by the interrupt handler to suspend the audio device
 * (if interrupts are enabled in IphoneAudioSupport).
 */
@property(readwrite,assign) bool suspended;

@end
