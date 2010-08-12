//
//  BackgroundAudio.m
//  ObjectAL
//
//  Created by Karl Stenerud on 19/12/09.
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

#import "BackgroundAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ObjectALMacros.h"
#import "IphoneAudioSupport.h"


#pragma mark Asynchronous Operations

/**
 * (INTERNAL USE) NSOperation for running an audio operation asynchronously.
 */
@interface AsyncAudioOperation: NSOperation
{
	/** The URL of the sound file to play */
	NSURL* url;
	/** The target to inform when the operation completes */
	id target;
	/** The selector to call when the operation completes */
	SEL selector;
}

/** (INTERNAL USE) Create a new Asynchronous Operation.
 *
 * @param url the URL containing the sound file.
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
+ (id) operationWithUrl:(NSURL*) url target:(id) target selector:(SEL) selector;

/** (INTERNAL USE) Initialize an Asynchronous Operation.
 *
 * @param url the URL containing the sound file.
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
- (id) initWithUrl:(NSURL*) url target:(id) target selector:(SEL) selector;

@end

@implementation AsyncAudioOperation

+ (id) operationWithUrl:(NSURL*) url target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithUrl:url target:target selector:selector] autorelease];
}

- (id) initWithUrl:(NSURL*) urlIn target:(id) targetIn selector:(SEL) selectorIn
{
	if(nil != (self = [super init]))
	{
		url = [urlIn retain];
		target = targetIn;
		selector = selectorIn;
	}
	return self;
}

- (void) dealloc
{
	[url release];
	
	[super dealloc];
}

@end


/**
 * (INTERNAL USE) NSOperation for playing an audio file asynchronously.
 */
@interface AsyncPlayOperation : AsyncAudioOperation
{
	NSInteger loops;
}

+ (id) operationWithUrl:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector;
- (id) initWithUrl:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector;

@end


@implementation AsyncPlayOperation

+ (id) operationWithUrl:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithUrl:url loops:loops target:target selector:selector] autorelease];
}

- (id) initWithUrl:(NSURL*) urlIn loops:(NSInteger) loopsIn target:(id) targetIn selector:(SEL) selectorIn
{
	if(nil != (self = [super initWithUrl:urlIn target:targetIn selector:selectorIn]))
	{
		loops = loopsIn;
	}
	return self;
}

- (id) initWithUrl:(NSURL*) urlIn target:(id) targetIn selector:(SEL) selectorIn
{
	return [self initWithUrl:urlIn loops:0 target:targetIn selector:selectorIn];
}

- (void)main
{
	[[BackgroundAudio sharedInstance] playUrl:url loops:loops];
	[target performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
}

@end


/**
 * (INTERNAL USE) NSOperation for preloading an audio file asynchronously.
 */
@interface AsyncPreloadOperation : AsyncAudioOperation
{
}

@end


@implementation AsyncPreloadOperation

- (void)main
{
	[[BackgroundAudio sharedInstance] preloadUrl:url];
	[target performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
}

@end

#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private interface to BackgroundAudio.
 */
@interface BackgroundAudio (Private)

/** (INTERNAL USE) Get an AudioSession property.
 *
 * @param property The property to get.
 * @return The property's value.
 */
- (UInt32) getIntProperty:(AudioSessionPropertyID) property;

/** (INTERNAL USE) Set an AudioSession property.
 *
 * @param property The property to set.
 * @param value The value to set this property to.
 */
- (void) setIntProperty:(AudioSessionPropertyID) property value:(UInt32) value;

/** (INTERNAL USE) Update AudioSession based on the allowIpod and honorSilentSwitch values.
 */
- (void) updateAudioMode;


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
#pragma mark BackgroundAudio

@implementation BackgroundAudio

#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(BackgroundAudio);

- (id) init
{
	if(nil != (self = [super init]))
	{
		operationQueue = [[NSOperationQueue alloc] init];
		operationQueue.maxConcurrentOperationCount = 1;
		gain = 1.0;
		numberOfLoops = 0;
		allowIpod = YES;
		honorSilentSwitch = YES;
		[self updateAudioMode];
	}
	return self;
}

- (void) dealloc
{
	[operationQueue release];
	[currentlyLoadedUrl release];
	[player release];
	[simulatorPlayerRef release];
	[super dealloc];
}


#pragma mark Properties

- (bool) allowIpod
{
	SYNCHRONIZED_OP(self)
	{
		return allowIpod;
	}
}

- (void) setAllowIpod:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		allowIpod = value;
		[self updateAudioMode];
	}
}

@synthesize currentlyLoadedUrl;

- (id<AVAudioPlayerDelegate>) delegate
{
	SYNCHRONIZED_OP(self)
	{
		return delegate;
	}
}

- (void) setDelegate:(id<AVAudioPlayerDelegate>) value
{
	SYNCHRONIZED_OP(self)
	{
		player.delegate = delegate = value;
	}
}

- (float) gain
{
	SYNCHRONIZED_OP(self)
	{
		return gain;
	}
}

- (void) setGain:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return muted;
	}
}

- (void) setMuted:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		muted = value;
		float resultingGain = muted ? 0 : gain;
		player.volume = resultingGain;
	}
}

- (bool) honorSilentSwitch
{
	SYNCHRONIZED_OP(self)
	{
		return honorSilentSwitch;
	}
}

- (void) setHonorSilentSwitch:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		honorSilentSwitch = value;
		[self updateAudioMode];
	}
}

- (NSInteger) numberOfLoops
{
	SYNCHRONIZED_OP(self)
	{
		return numberOfLoops;
	}
}

- (void) setNumberOfLoops:(NSInteger) value
{
	SYNCHRONIZED_OP(self)
	{
		player.numberOfLoops = numberOfLoops = value;
	}
}

- (bool) paused
{
	SYNCHRONIZED_OP(self)
	{
		return paused;
	}
}

- (void) setPaused:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		if(paused != value)
		{
			paused = value;
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

@synthesize player;

@synthesize playing;

- (bool) ipodPlaying
{
	return 0 != [self getIntProperty:kAudioSessionProperty_OtherAudioIsPlaying];
}

- (NSTimeInterval) currentTime
{
	SYNCHRONIZED_OP(self)
	{
		return player.currentTime;
	}
}

- (void) setCurrentTime:(NSTimeInterval) value
{
	SYNCHRONIZED_OP(self)
	{
		player.currentTime = value;
	}
}

- (NSTimeInterval) duration
{
	SYNCHRONIZED_OP(self)
	{
		return player.duration;
	}
}

- (NSUInteger) numberOfChannels
{
	SYNCHRONIZED_OP(self)
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

	SYNCHRONIZED_OP(self)
	{
		if(suspended)
		{
			LOG_ERROR(@"Could not load URL %@: Audio is still suspended", url);
			return NO;
		}
		
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
	SYNCHRONIZED_OP(self)
	{
		[operationQueue addOperation:[AsyncPreloadOperation operationWithUrl:url target:target selector:selector]];
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
	SYNCHRONIZED_OP(self)
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
	[operationQueue addOperation:[AsyncPlayOperation operationWithUrl:url loops:loops target:target selector:selector]];
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
	SYNCHRONIZED_OP(self)
	{
		if(suspended)
		{
			LOG_ERROR(@"Could not play: Audio is still suspended");
			return NO;
		}
		
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
	SYNCHRONIZED_OP(self)
	{
		[player stop];
		player.currentTime = 0;
		SIMULATOR_BUG_WORKAROUND_END_PLAYBACK();
		paused = NO;
		playing = NO;
	}
}

- (void) clear
{
	SYNCHRONIZED_OP(self)
	{
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


#pragma mark Internal Utility

- (UInt32) getIntProperty:(AudioSessionPropertyID) property
{
	UInt32 value;
	UInt32 size = sizeof(value);
	OSStatus result;
	SYNCHRONIZED_OP(self)
	{
		result = AudioSessionGetProperty(property, &size, &value);
	}
	REPORT_AUDIOSESSION_CALL(result, @"Failed to get int property %08x", property);
	return value;
}

- (void) setIntProperty:(AudioSessionPropertyID) property value:(UInt32) value
{
	OSStatus result;
	SYNCHRONIZED_OP(self)
	{
		result = AudioSessionSetProperty(property, sizeof(value), &value);
	}
	REPORT_AUDIOSESSION_CALL(result, @"Failed to get int property %08x", property);
}

- (void) updateAudioMode
{
#if !TARGET_IPHONE_SIMULATOR
	// Note: Simulator doesn't support setting the audio category
	if(honorSilentSwitch)
	{
		if(allowIpod)
		{
			[self setIntProperty:kAudioSessionProperty_AudioCategory value:kAudioSessionCategory_AmbientSound];
		}
		else
		{
			[self setIntProperty:kAudioSessionProperty_AudioCategory value:kAudioSessionCategory_SoloAmbientSound];
		}
	}
	else
	{
		[self setIntProperty:kAudioSessionProperty_AudioCategory value:kAudioSessionCategory_MediaPlayback];
		if(allowIpod)
		{
			[self setIntProperty:kAudioSessionProperty_OverrideCategoryMixWithOthers value:TRUE];
		}
		else
		{
			[self setIntProperty:kAudioSessionProperty_OverrideCategoryMixWithOthers value:FALSE];
		}
	}
#endif /* !TARGET_IPHONE_SIMULATOR */
}


#pragma mark Metering

- (bool) meteringEnabled
{
	SYNCHRONIZED_OP(self)
	{
		return meteringEnabled;
	}
}

- (void) setMeteringEnabled:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		meteringEnabled = value;
		player.meteringEnabled = meteringEnabled;
	}
}

- (void) updateMeters
{
	SYNCHRONIZED_OP(self)
	{
		[player updateMeters];
	}
}

- (float) averagePowerForChannel:(NSUInteger)channelNumber
{
	SYNCHRONIZED_OP(self)
	{
		return [player averagePowerForChannel:channelNumber];
	}
}

- (float) peakPowerForChannel:(NSUInteger)channelNumber
{
	SYNCHRONIZED_OP(self)
	{
		return [player peakPowerForChannel:channelNumber];
	}
}


#pragma mark Internal Use

- (bool) suspended
{
	SYNCHRONIZED_OP(self)
	{
		return suspended;
	}
}

- (void) setSuspended:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		if(suspended != value)
		{
			suspended = value;
			if(suspended)
			{
				AudioSessionSetActive(NO);
			}
			else
			{
				[self updateAudioMode];
				AudioSessionSetActive(YES);
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
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
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
