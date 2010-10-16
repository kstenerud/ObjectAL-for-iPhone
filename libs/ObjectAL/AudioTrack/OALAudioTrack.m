//
//  OALAudioTrack.m
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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALAudioTrack.h"
#import "mach_timing.h"
#import <AudioToolbox/AudioToolbox.h>
#import "OALAudioActions.h"
#import "OALAudioTracks.h"
#import "OALAudioSupport.h"
#import "OALUtilityActions.h"
#import "ObjectALMacros.h"

#pragma mark Asynchronous Operations

/**
 * (INTERNAL USE) NSOperation for running an audio operation asynchronously.
 */
@interface OAL_AsyncAudioTrackOperation: NSOperation
{
	/** The audio track object to perform the operation on */
	OALAudioTrack* audioTrack;
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
+ (id) operationWithTrack:(OALAudioTrack*) track url:(NSURL*) url target:(id) target selector:(SEL) selector;

/** (INTERNAL USE) Initialize an Asynchronous Operation.
 *
 * @param track the audio track to perform the operation on.
 * @param url the URL containing the sound file.
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
- (id) initWithTrack:(OALAudioTrack*) track url:(NSURL*) url target:(id) target selector:(SEL) selector;

@end

@implementation OAL_AsyncAudioTrackOperation

+ (id) operationWithTrack:(OALAudioTrack*) track url:(NSURL*) url target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithTrack:track url:url target:target selector:selector] autorelease];
}

- (id) initWithTrack:(OALAudioTrack*) track url:(NSURL*) urlIn target:(id) targetIn selector:(SEL) selectorIn
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
@interface OAL_AsyncAudioTrackPlayOperation : OAL_AsyncAudioTrackOperation
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
+ (id) operationWithTrack:(OALAudioTrack*) track url:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector;

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
- (id) initWithTrack:(OALAudioTrack*) track url:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector;

@end


@implementation OAL_AsyncAudioTrackPlayOperation

+ (id) operationWithTrack:(OALAudioTrack*) track url:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithTrack:track url:url loops:loops target:target selector:selector] autorelease];
}

- (id) initWithTrack:(OALAudioTrack*) track url:(NSURL*) urlIn loops:(NSInteger) loopsIn target:(id) targetIn selector:(SEL) selectorIn
{
	if(nil != (self = [super initWithTrack:track url:urlIn target:targetIn selector:selectorIn]))
	{
		loops = loopsIn;
	}
	return self;
}

- (id) initWithTrack:(OALAudioTrack*) track url:(NSURL*) urlIn target:(id) targetIn selector:(SEL) selectorIn
{
	return [self initWithTrack:track url:urlIn loops:0 target:targetIn selector:selectorIn];
}

- (void)main
{
	[audioTrack playUrl:url loops:loops];
	[target performSelectorOnMainThread:selector withObject:audioTrack waitUntilDone:NO];
}

@end


/**
 * (INTERNAL USE) NSOperation for preloading an audio file asynchronously.
 */
@interface OAL_AsyncAudioTrackPreloadOperation : OAL_AsyncAudioTrackOperation
{
}

@end


@implementation OAL_AsyncAudioTrackPreloadOperation

- (void)main
{
	[audioTrack preloadUrl:url];
	[target performSelectorOnMainThread:selector withObject:audioTrack waitUntilDone:NO];
}

@end

#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private interface to AudioTrack.
 */
@interface OALAudioTrack (Private)

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

@implementation OALAudioTrack

#pragma mark Object Management

+ (id) track
{
	return [[[self alloc] init] autorelease];
}

- (id) init
{
	if(nil != (self = [super init]))
	{
		// Make sure OALAudioTracks is initialized.
		[OALAudioTracks sharedInstance];
		
		operationQueue = [[NSOperationQueue alloc] init];
		operationQueue.maxConcurrentOperationCount = 1;
		gain = 1.0f;
		numberOfLoops = 0;
		currentTime = 0.0;
		
		[[OALAudioTracks sharedInstance] notifyTrackInitializing:self];
	}
	return self;
}

- (void) dealloc
{
	[[OALAudioTracks sharedInstance] notifyTrackDeallocating:self];

	[operationQueue release];
	[currentlyLoadedUrl release];
	[player release];
	[simulatorPlayerRef release];
	[gainAction stopAction];
	[gainAction release];
	[panAction stopAction];
	[panAction release];
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
		delegate = value;
	}
}

- (float) pan
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return pan;
	}
}

- (void) setPan:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(isIOS40OrHigher)
		{
			pan = value;
			player.pan = pan;
		}
	}
}

- (float) volume
{
	return self.gain;
}

- (float) gain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return gain;
	}
}

- (void) setVolume:(float) value
{
	self.gain = value;
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
			[self stopActions];
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
					if(playing)
						[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStoppedPlayingNotification object:self] waitUntilDone:NO];
				}
				else if(playing)
				{
					playing = [player play];
					if(playing)
						[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStartedPlayingNotification object:self] waitUntilDone:NO];
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
		currentTime = value;
	}
}

- (NSTimeInterval) deviceCurrentTime
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(isIOS40OrHigher)
		{
			return player.deviceCurrentTime;
		}
		return 0;
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
		OAL_LOG_ERROR(@"Cannot open NULL file / url");
		return NO;
	}
	
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspended)
		{
			OAL_LOG_ERROR(@"Could not load URL %@: Audio is still suspended", url);
			return NO;
		}
		
		// Only load if it's not the same URL as last time.
		if([[url absoluteString] isEqualToString:[currentlyLoadedUrl absoluteString]])
		{
			return NO;
		}
		
		[self stopActions];
		
		// Only load if it's not the same URL as last time.
		//if(![[url absoluteString] isEqualToString:[currentlyLoadedUrl absoluteString]])
		//{
			SIMULATOR_BUG_WORKAROUND_PREPARE_PLAYBACK();
			[player stop];
			[player release];
		if(playing)
			[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStoppedPlayingNotification object:self] waitUntilDone:NO];
		
			NSError* error;
			player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
			if(nil != error)
			{
				OAL_LOG_ERROR(@"Could not load URL %@: %@", url, [error localizedDescription]);
				return NO;
			}
			
			player.volume = muted ? 0 : gain;
			player.numberOfLoops = numberOfLoops;
			player.meteringEnabled = meteringEnabled;
			player.delegate = self;
			isIOS40OrHigher = [player respondsToSelector:@selector(pan)];
			if(isIOS40OrHigher)
			{
				player.pan = pan;
			}
			
			[currentlyLoadedUrl release];
			currentlyLoadedUrl = [url retain];
		//}
		
		player.currentTime = currentTime;
		playing = NO;
		paused = NO;
		BOOL allOK = [player prepareToPlay];
		if(!allOK){
			OAL_LOG_ERROR(@"Failed to prepareToPlay: %@", url);
		}else{
			[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackSourceChangedNotification object:self] waitUntilDone:NO];
		}
		return allOK;
	}
}

- (bool) preloadFile:(NSString*) path
{
	return [self preloadUrl:[[OALAudioSupport sharedInstance] urlForPath:path]];
}

- (bool) preloadUrlAsync:(NSURL*) url target:(id) target selector:(SEL) selector
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[operationQueue addOperation:[OAL_AsyncAudioTrackPreloadOperation operationWithTrack:self url:url target:target selector:selector]];
		return NO;
	}
}

- (bool) preloadFileAsync:(NSString*) path target:(id) target selector:(SEL) selector
{
	return [self preloadUrlAsync:[[OALAudioSupport sharedInstance] urlForPath:path] target:target selector:selector];
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
	return [self playUrl:[[OALAudioSupport sharedInstance] urlForPath:path]];
}

- (bool) playFile:(NSString*) path loops:(NSInteger) loops
{
	return [self playUrl:[[OALAudioSupport sharedInstance] urlForPath:path] loops:loops];
}

- (void) playUrlAsync:(NSURL*) url target:(id) target selector:(SEL) selector
{
	[self playUrlAsync:url loops:0 target:target selector:selector];
}

- (void) playUrlAsync:(NSURL*) url loops:(NSInteger) loops target:(id) target selector:(SEL) selector
{
	[operationQueue addOperation:[OAL_AsyncAudioTrackPlayOperation operationWithTrack:self url:url loops:loops target:target selector:selector]];
}

- (void) playFileAsync:(NSString*) path target:(id) target selector:(SEL) selector
{
	[self playFileAsync:path loops:0 target:target selector:selector];
}

- (void) playFileAsync:(NSString*) path loops:(NSInteger) loops target:(id) target selector:(SEL) selector
{
	[self playUrlAsync:[[OALAudioSupport sharedInstance] urlForPath:path] loops:loops target:target selector:selector];
}

- (bool) play
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspended)
		{
			OAL_LOG_ERROR(@"Could not play: Audio is still suspended");
			return NO;
		}
		
		[self stopActions];
		SIMULATOR_BUG_WORKAROUND_PREPARE_PLAYBACK();
		player.currentTime = currentTime;
		player.volume = muted ? 0 : gain;
		player.numberOfLoops = numberOfLoops;
		paused = NO;
		playing = [player play];
		if(playing)
			[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStartedPlayingNotification object:self] waitUntilDone:NO];
		return playing;
	}
}

- (bool) playAtTime:(NSTimeInterval) time
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspended)
		{
			OAL_LOG_ERROR(@"Could not play: Audio is still suspended");
			return NO;
		}
		
		if(isIOS40OrHigher)
		{
			[self stopActions];
			SIMULATOR_BUG_WORKAROUND_PREPARE_PLAYBACK();
			player.currentTime = currentTime;
			player.volume = muted ? 0 : gain;
			player.numberOfLoops = numberOfLoops;
			paused = NO;
			playing = [player playAtTime:time];
			if(playing){
				[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStartedPlayingNotification object:self] waitUntilDone:NO];
			}
			return playing;
		}
		return NO;
	}
}

- (void) stop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[self stopActions];
		[player stop];
		if(playing)
			[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStoppedPlayingNotification object:self] waitUntilDone:NO];
		
		self.currentTime = 0;
		player.currentTime = 0;
		SIMULATOR_BUG_WORKAROUND_END_PLAYBACK();
		paused = NO;
		playing = NO;
	}
}

- (void) stopActions
{
	[self stopFade];
	[self stopPan];
}


- (void) fadeTo:(float) value
	   duration:(float) duration
		 target:(id) target
	   selector:(SEL) selector
{
	// Must always be synchronized
	@synchronized(self)
	{
		[self stopFade];
		gainAction = [[OALSequentialActions actions:
					   [OALGainAction actionWithDuration:duration endValue:value],
					   [OALCallAction actionWithCallTarget:target selector:selector withObject:self],
					   nil] retain];
		[gainAction runWithTarget:self];
	}
}

- (void) stopFade
{
	// Must always be synchronized
	@synchronized(self)
	{
		[gainAction stopAction];
		[gainAction release];
		gainAction = nil;
	}
}

- (void) panTo:(float) value
	  duration:(float) duration
		target:(id) target
	  selector:(SEL) selector
{
	if(isIOS40OrHigher)
	{
		// Must always be synchronized
		@synchronized(self)
		{
			[self stopPan];
			panAction = [[OALSequentialActions actions:
						  [OALPanAction actionWithDuration:duration endValue:value],
						  [OALCallAction actionWithCallTarget:target selector:selector withObject:self],
						  nil] retain];
			[panAction runWithTarget:self];
		}
	}
}

- (void) stopPan
{
	if(isIOS40OrHigher)
	{
		// Must always be synchronized
		@synchronized(self)
		{
			[panAction stopAction];
			[panAction release];
			panAction = nil;
		}
	}
}

- (void) clear
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[self stopActions];
		[currentlyLoadedUrl release];
		currentlyLoadedUrl = nil;
		
		[player stop];
		[player release];
		if(playing)
			[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStoppedPlayingNotification object:self] waitUntilDone:NO];
		
		self.currentTime = 0;
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
				if(playing)
					[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStoppedPlayingNotification object:self] waitUntilDone:NO];
			}
			else if(playing && !paused)
			{
				playing = [player play];
				if(playing)
					[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackStartedPlayingNotification object:self] waitUntilDone:NO];
			}
		}
	}
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

#if TARGET_OS_IPHONE
- (void) audioPlayerBeginInterruption:(AVAudioPlayer*) playerIn
{
	currentTime = self.currentTime;
	if([delegate respondsToSelector:@selector(audioPlayerBeginInterruption:)])
	{
		[delegate audioPlayerBeginInterruption:playerIn];
	}
}

#if defined(__MAC_10_7) || defined(__IPHONE_4_0)
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)playerIn withFlags:(NSUInteger)flags
{
	if([delegate respondsToSelector:@selector(audioPlayerEndInterruption:withFlags:)])
	{
		[delegate audioPlayerEndInterruption:playerIn withFlags:flags];
	}
}
#endif

- (void) audioPlayerEndInterruption:(AVAudioPlayer*) playerIn
{
	if([delegate respondsToSelector:@selector(audioPlayerEndInterruption:)])
	{
		[delegate audioPlayerEndInterruption:playerIn];
	}
}
#endif //TARGET_OS_IPHONE

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
		self.currentTime = 0;
		SIMULATOR_BUG_WORKAROUND_END_PLAYBACK();
	}
	if([delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying:successfully:)])
	{
		[delegate audioPlayerDidFinishPlaying:playerIn successfully:flag];
	}
	
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:OALAudioTrackFinishedPlayingNotification object:self] waitUntilDone:NO];
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
