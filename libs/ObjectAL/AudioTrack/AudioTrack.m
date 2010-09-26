//
//  AudioTrack.m
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

#import "AudioTrack.h"
#import "AudioTracks.h"
#import "mach_timing.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ObjectALMacros.h"
#import "IphoneAudioSupport.h"


#pragma mark Asynchronous Operations

/**
 * (INTERNAL USE) NSOperation for running an audio operation asynchronously.
 */
@interface AsyncAudioTrackOperation: NSOperation
{
	/** The audio track object to perform the operation on */
	AudioTrack* audioTrack;
	/** The URL of the sound file to play */
	NSURL* url;
	/** The target to inform when the operation completes */
	id target;
	/** The selector to call when the operation completes */
	SEL selector;
}

/** (INTERNAL USE) Create a new Asynchronous Operation.
 *
 * @param track the audio track to perform the operation on.
 * @param url the URL containing the sound file.
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
+ (id) operationWithTrack:(AudioTrack*) track url:(NSURL*) url target:(id) target selector:(SEL) selector;

/** (INTERNAL USE) Initialize an Asynchronous Operation.
 *
 * @param track the audio track to perform the operation on.
 * @param url the URL containing the sound file.
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
- (id) initWithTrack:(AudioTrack*) track url:(NSURL*) url target:(id) target selector:(SEL) selector;

@end

@implementation AsyncAudioTrackOperation

+ (id) operationWithTrack:(AudioTrack*) track url:(NSURL*) url target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithTrack:track url:url target:target selector:selector] autorelease];
}

- (id) initWithTrack:(AudioTrack*) track url:(NSURL*) urlIn target:(id) targetIn selector:(SEL) selectorIn
{
	if(nil != (self = [super init]))
	{
		audioTrack = [track retain];
		url = [urlIn retain];
		target = targetIn;
		selector = selectorIn;
	}
	return self;
}

- (void) dealloc
{
	[audioTrack release];
	[url release];
	
	[super dealloc];
}

@end


/**
 * (INTERNAL USE) NSOperation for playing an audio file asynchronously.
 */
@interface AsyncAudioTrackPlayOperation : AsyncAudioTrackOperation
{
	/** The number of times to loop during playback */
	NSInteger loops;
}

/**
 * (INTERNAL USE) Create an asynchronous play operation.
 *
 * @param track the audio track to perform the operation on.
 * @param url The URL of the file to play.
 * @param loops The number of times to loop playback (-1 = forever).
 * @param target The target to inform when playback finishes.
 * @param selector the selector to call when playback finishes.
 * @return a new operation.
 */
+ (id) operationWithTrack:(AudioTrack*) track url:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector;

/**
 * (INTERNAL USE) Initialize an asynchronous play operation.
 *
 * @param track the audio track to perform the operation on.
 * @param url The URL of the file to play.
 * @param loops The number of times to loop playback (-1 = forever).
 * @param target The target to inform when playback finishes.
 * @param selector the selector to call when playback finishes.
 * @return The initialized operation.
 */
- (id) initWithTrack:(AudioTrack*) track url:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector;

@end


@implementation AsyncAudioTrackPlayOperation

+ (id) operationWithTrack:(AudioTrack*) track url:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithTrack:track url:url loops:loops target:target selector:selector] autorelease];
}

- (id) initWithTrack:(AudioTrack*) track url:(NSURL*) urlIn loops:(NSInteger) loopsIn target:(id) targetIn selector:(SEL) selectorIn
{
	if(nil != (self = [super initWithTrack:track url:urlIn target:targetIn selector:selectorIn]))
	{
		loops = loopsIn;
	}
	return self;
}

- (id) initWithTrack:(AudioTrack*) track url:(NSURL*) urlIn target:(id) targetIn selector:(SEL) selectorIn
{
	return [self initWithTrack:track url:urlIn loops:0 target:targetIn selector:selectorIn];
}

- (void)main
{
	[audioTrack playUrl:url loops:loops];
	[target performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
}

@end


/**
 * (INTERNAL USE) NSOperation for preloading an audio file asynchronously.
 */
@interface AsyncAudioTrackPreloadOperation : AsyncAudioTrackOperation
{
}

@end


@implementation AsyncAudioTrackPreloadOperation

- (void)main
{
	[audioTrack preloadUrl:url];
	[target performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
}

@end

#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private interface to AudioTrack.
 */
@interface AudioTrack (Private)

#if TARGET_IPHONE_SIMULATOR && OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND

/** If the background music playback on the simulator ends (or is stopped), it mutes
 * OpenAL audio.  This method works around the issue by putting the player into looped
 * playback mode with volume set to 0 until the next instruction is received.
 */
- (void) simulatorBugWorkaroundHoldPlayer;

/** Part of the simulator bug workaround
 */
- (void) simulatorBugWorkaroundRestorePlayer;


#define SIMULATOR_BUG_WORKAROUND_PREPARE_PLAYBACK() [self simulatorBugWorkaroundRestorePlayer]
#define SIMULATOR_BUG_WORKAROUND_END_PLAYBACK() [self simulatorBugWorkaroundHoldPlayer]

#else /* TARGET_IPHONE_SIMULATOR && OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND */

#define SIMULATOR_BUG_WORKAROUND_PREPARE_PLAYBACK()
#define SIMULATOR_BUG_WORKAROUND_END_PLAYBACK()

#endif /* TARGET_IPHONE_SIMULATOR && OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND */

@end

#pragma mark -
#pragma mark AudioTrack

@implementation AudioTrack

#pragma mark Object Management

+ (id) track
{
	return [[[self alloc] init] autorelease];
}

- (id) init
{
	if(nil != (self = [super init]))
	{
		// Make sure AudioTracks is initialized.
		[AudioTracks sharedInstance];
		
		operationQueue = [[NSOperationQueue alloc] init];
		operationQueue.maxConcurrentOperationCount = 1;
		gain = 1.0;
		numberOfLoops = 0;
		
		[[AudioTracks sharedInstance] notifyTrackInitializing:self];
	}
	return self;
}

- (void) dealloc
{
	[[AudioTracks sharedInstance] notifyTrackDeallocating:self];

	[operationQueue release];
	[currentlyLoadedUrl release];
	[player release];
	[simulatorPlayerRef release];
	[super dealloc];
}


#pragma mark Properties

@synthesize currentlyLoadedUrl;

- (id<AVAudioPlayerDelegate>) delegate
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return delegate;
	}
}

- (void) setDelegate:(id<AVAudioPlayerDelegate>) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		player.delegate = delegate = value;
	}
}

- (float) gain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return gain;
	}
}

- (void) setGain:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		gain = value;
		if(muted)
		{
			value = 0;
		}
		player.volume = value;
	}
}

- (bool) muted
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return muted;
	}
}

- (void) setMuted:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		muted = value;
		if(muted)
		{
			[self stopFade];
		}
		float resultingGain = muted ? 0 : gain;
		player.volume = resultingGain;
	}
}

- (NSInteger) numberOfLoops
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return numberOfLoops;
	}
}

- (void) setNumberOfLoops:(NSInteger) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		player.numberOfLoops = numberOfLoops = value;
	}
}

- (bool) paused
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return paused;
	}
}

- (void) setPaused:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(paused != value)
		{
			paused = value;
			if(!suspended)
			{
				if(paused)
				{
					[player pause];
				}
				else if(playing)
				{
					[player play];
				}
			}
		}
	}
}

@synthesize player;

@synthesize playing;

- (NSTimeInterval) currentTime
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return player.currentTime;
	}
}

- (void) setCurrentTime:(NSTimeInterval) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		player.currentTime = value;
	}
}

- (NSTimeInterval) duration
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return player.duration;
	}
}

- (NSUInteger) numberOfChannels
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return player.numberOfChannels;
	}
}


#pragma mark Playback

- (bool) preloadUrl:(NSURL*) url
{
	if(nil == url)
	{
		LOG_ERROR(@"Cannot open NULL file / url");
		return NO;
	}
	
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspended)
		{
			LOG_ERROR(@"Could not load URL %@: Audio is still suspended", url);
			return NO;
		}
		
		[self stopFade];
		
		// Only load if it's not the same URL as last time.
		if(![url isEqual:currentlyLoadedUrl])
		{
			SIMULATOR_BUG_WORKAROUND_PREPARE_PLAYBACK();
			[player stop];
			[player release];
			NSError* error;
			player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
			if(nil != error)
			{
				LOG_ERROR(@"Could not load URL %@: %@", url, [error localizedDescription]);
				return NO;
			}
			
			player.volume = muted ? 0 : gain;
			player.numberOfLoops = numberOfLoops;
			player.meteringEnabled = meteringEnabled;
			player.delegate = self;
			
			[currentlyLoadedUrl release];
			currentlyLoadedUrl = [url retain];
		}
		
		player.currentTime = 0;
		playing = NO;
		paused = NO;
		return [player prepareToPlay];
	}
}

- (bool) preloadFile:(NSString*) path
{
	return [self preloadUrl:[[IphoneAudioSupport sharedInstance] urlForPath:path]];
}

- (bool) preloadUrlAsync:(NSURL*) url target:(id) target selector:(SEL) selector
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[operationQueue addOperation:[AsyncAudioTrackPreloadOperation operationWithTrack:self url:url target:target selector:selector]];
		return NO;
	}
}

- (bool) preloadFileAsync:(NSString*) path target:(id) target selector:(SEL) selector
{
	return [self preloadUrlAsync:[[IphoneAudioSupport sharedInstance] urlForPath:path] target:target selector:selector];
}

- (bool) playUrl:(NSURL*) url
{
	return [self playUrl:url loops:0];
}

- (bool) playUrl:(NSURL*) url loops:(NSInteger) loops
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if([self preloadUrl:url])
		{
			self.numberOfLoops = loops;
			return [self play];
		}
		return NO;
	}
}

- (bool) playFile:(NSString*) path
{
	return [self playUrl:[[IphoneAudioSupport sharedInstance] urlForPath:path]];
}

- (bool) playFile:(NSString*) path loops:(NSInteger) loops
{
	return [self playUrl:[[IphoneAudioSupport sharedInstance] urlForPath:path] loops:loops];
}

- (void) playUrlAsync:(NSURL*) url target:(id) target selector:(SEL) selector
{
	[self playUrlAsync:url loops:0 target:target selector:selector];
}

- (void) playUrlAsync:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector
{
	[operationQueue addOperation:[AsyncAudioTrackPlayOperation operationWithTrack:self url:url loops:loops target:target selector:selector]];
}

- (void) playFileAsync:(NSString*) path target:(id) target selector:(SEL) selector
{
	[self playFileAsync:path loops:0 target:target selector:selector];
}

- (void) playFileAsync:(NSString*) path loops:(NSInteger) loops target:(id) target selector:(SEL) selector
{
	[self playUrlAsync:[[IphoneAudioSupport sharedInstance] urlForPath:path] loops:loops target:target selector:selector];
}

- (bool) play
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspended)
		{
			LOG_ERROR(@"Could not play: Audio is still suspended");
			return NO;
		}
		
		[self stopFade];
		SIMULATOR_BUG_WORKAROUND_PREPARE_PLAYBACK();
		player.currentTime = 0;
		player.volume = muted ? 0 : gain;
		player.numberOfLoops = numberOfLoops;
		paused = NO;
		playing = [player play];
		return playing;
	}
}

- (void) stop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[self stopFade];
		[player stop];
		player.currentTime = 0;
		SIMULATOR_BUG_WORKAROUND_END_PLAYBACK();
		paused = NO;
		playing = NO;
	}
}

- (void) fadeStep:(NSTimer*) timer
{
	// Must always be synchronized
	@synchronized(self)
	{
		if(0 != fadeStartTime)
		{
			float elapsedTime = mach_absolute_difference_seconds(mach_absolute_time(), fadeStartTime);
			
			float newGain = elapsedTime >= fadeDuration ? fadeEndingGain : fadeStartingGain + elapsedTime * fadeDeltaMultiplier;
			
			self.gain = newGain;
			
			if(newGain == fadeEndingGain)
			{
				[self stopFade];
				[fadeCompleteTarget performSelector:fadeCompleteSelector withObject:self];
			}
		}
	}
}

- (void) fadeTo:(float) value duration:(float) duration target:(id) target selector:(SEL) selector
{
	// Must always be synchronized
	@synchronized(self)
	{
		[self stopFade];
		fadeCompleteTarget = target;
		fadeCompleteSelector = selector;
		fadeStartingGain = self.gain;
		fadeEndingGain = value;
		
		float delta = fadeEndingGain - fadeStartingGain;
		
		if(0 == delta)
		{
			// Handle case where there is no fading to be done.
			[fadeCompleteTarget performSelector:fadeCompleteSelector withObject:self];
		}
		else
		{
			fadeDuration = duration;
			fadeDeltaMultiplier = delta / fadeDuration;
			fadeStartTime = mach_absolute_time();
			
			fadeTimer = [NSTimer scheduledTimerWithTimeInterval:kAudioTrack_FadeInterval
														 target:self
													   selector:@selector(fadeStep:)
													   userInfo:nil
														repeats:YES];
		}
	}
}

- (void) stopFade
{
	// Must always be synchronized
	@synchronized(self)
	{
		fadeStartTime = 0;
		[fadeTimer invalidate];
		fadeTimer = nil;
	}
}

- (void) clear
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[self stopFade];
		[currentlyLoadedUrl release];
		currentlyLoadedUrl = nil;
		
		[player stop];
		[player release];
		player = nil;
		playing = NO;
		paused = NO;
		muted = NO;
	}
}


#pragma mark Metering

- (bool) meteringEnabled
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return meteringEnabled;
	}
}

- (void) setMeteringEnabled:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		meteringEnabled = value;
		player.meteringEnabled = meteringEnabled;
	}
}

- (void) updateMeters
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[player updateMeters];
	}
}

- (float) averagePowerForChannel:(NSUInteger)channelNumber
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [player averagePowerForChannel:channelNumber];
	}
}

- (float) peakPowerForChannel:(NSUInteger)channelNumber
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [player peakPowerForChannel:channelNumber];
	}
}


#pragma mark Internal Use

- (bool) suspended
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return suspended;
	}
}

- (void) setSuspended:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspended != value)
		{
			suspended = value;
			if(suspended)
			{
				[player pause];
			}
			else if(playing && !paused)
			{
				[player play];
			}
		}
	}
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void) audioPlayerBeginInterruption:(AVAudioPlayer*) playerIn
{
	if([delegate respondsToSelector:@selector(audioPlayerBeginInterruption:)])
	{
		[delegate audioPlayerBeginInterruption:playerIn];
	}
}

- (void) audioPlayerEndInterruption:(AVAudioPlayer*) playerIn
{
	if([delegate respondsToSelector:@selector(audioPlayerEndInterruption:)])
	{
		[delegate audioPlayerEndInterruption:playerIn];
	}
}

- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*) playerIn error:(NSError*) error
{
	if([delegate respondsToSelector:@selector(audioPlayerDecodeErrorDidOccur:error:)])
	{
		[delegate audioPlayerDecodeErrorDidOccur:playerIn error:error];
	}
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer*) playerIn successfully:(BOOL) flag
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		playing = NO;
		paused = NO;
		SIMULATOR_BUG_WORKAROUND_END_PLAYBACK();
	}
	if([delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying:successfully:)])
	{
		[delegate audioPlayerDidFinishPlaying:playerIn successfully:flag];
	}
}

#pragma mark -
#pragma mark Simulator playback bug handler

#if TARGET_IPHONE_SIMULATOR && OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND

- (void) simulatorBugWorkaroundRestorePlayer
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(nil != simulatorPlayerRef)
		{
			player = simulatorPlayerRef;
			simulatorPlayerRef = nil;
			[player stop];
			player.numberOfLoops = numberOfLoops;
			player.volume = gain;
		}
	}
}

- (void) simulatorBugWorkaroundHoldPlayer
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(nil != player)
		{
			player.volume = 0;
			player.numberOfLoops = -1;
			[player play];
			simulatorPlayerRef = player;
			player = nil;
		}
	}
}

#endif /* TARGET_IPHONE_SIMULATOR && OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND */

@end
