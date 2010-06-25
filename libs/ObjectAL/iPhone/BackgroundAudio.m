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
}

@end


@implementation AsyncPlayOperation

- (void)main
{
	[[BackgroundAudio sharedInstance] playUrl:url];
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
		allowIpod = NO;
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
	[super dealloc];
}


#pragma mark Properties

@synthesize allowIpod;

- (void) setAllowIpod:(bool) value
{
	allowIpod = value;
	[self updateAudioMode];
}

@synthesize currentlyLoadedUrl;

@synthesize delegate;

- (void) setDelegate:(id<AVAudioPlayerDelegate>) value
{
	player.delegate = delegate = value;
}

@synthesize gain;

- (void) setGain:(float) value
{
	player.volume = gain = value;
}

@synthesize honorSilentSwitch;

- (void) setHonorSilentSwitch:(bool) value
{
	honorSilentSwitch = value;
	[self updateAudioMode];
}

@synthesize numberOfLoops;

- (void) setNumberOfLoops:(NSInteger) value
{
	player.numberOfLoops = numberOfLoops = value;
}

@synthesize paused;

- (void) setPaused:(bool) value
{
	if(paused != value)
	{
		paused = value;
		if(paused)
		{
			wasPlaying = player.playing;
			[player pause];
		}
		else if(wasPlaying)
		{
			[player play];
		}
	}
}

@synthesize player;

- (bool) playing
{
	return player.playing;
}

- (bool) ipodPlaying
{
	return 0 != [self getIntProperty:kAudioSessionProperty_OtherAudioIsPlaying];
}

- (NSTimeInterval) currentTime
{
	return player.currentTime;
}

- (void) setCurrentTime:(NSTimeInterval) value
{
	player.currentTime = value;
}

- (NSTimeInterval) duration
{
	return player.duration;
}

- (NSUInteger) numberOfChannels
{
	return player.numberOfChannels;
}


#pragma mark Playback

- (bool) preloadUrl:(NSURL*) url
{
	if(nil == url)
	{
		NSLog(@"Error: BackgroundAudio: Cannot open NULL file / url");
		return NO;
	}

	if(suspended)
	{
		NSLog(@"Error: BackgroundAudio: Could not load URL %@: Audio is still suspended", url);
		return NO;
	}
	
	// Only load if it's not the same URL as last time.
	if(![url isEqual:currentlyLoadedUrl])
	{
		[player stop];
		[player release];
		NSError* error;
		player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
		if(nil != error)
		{
			NSLog(@"Error: BackgroundAudio: Could not load URL %@: %@", url, [error localizedDescription]);
			return NO;
		}

		player.volume = gain;
		player.numberOfLoops = numberOfLoops;
		player.meteringEnabled = meteringEnabled;
		
#if TARGET_IPHONE_SIMULATOR
		player.delegate = self;
#else /* TARGET_IPHONE_SIMULATOR */
		player.delegate = delegate;
#endif /* TARGET_IPHONE_SIMULATOR */
		
		currentlyLoadedUrl = [url retain];
	}
	
	player.currentTime = 0;
	return [player prepareToPlay];
}

- (bool) preloadFile:(NSString*) path
{
	return [self preloadUrl:[[IphoneAudioSupport sharedInstance] urlForPath:path]];
}

- (bool) preloadUrlAsync:(NSURL*) url target:(id) target selector:(SEL) selector
{
	[operationQueue addOperation:[AsyncPreloadOperation operationWithUrl:url target:target selector:selector]];
	return NO;
}

- (bool) preloadFileAsync:(NSString*) path target:(id) target selector:(SEL) selector
{
	return [self preloadUrlAsync:[[IphoneAudioSupport sharedInstance] urlForPath:path] target:target selector:selector];
}

- (bool) playUrl:(NSURL*) url
{
	if([self preloadUrl:url])
	{
		return [self play];
	}
	return NO;
}

- (bool) playFile:(NSString*) path
{
	return [self playUrl:[[IphoneAudioSupport sharedInstance] urlForPath:path]];
}

- (bool) playUrlAsync:(NSURL*) url target:(id) target selector:(SEL) selector
{
	[operationQueue addOperation:[AsyncPlayOperation operationWithUrl:url target:target selector:selector]];
	return NO;
}

- (bool) playFileAsync:(NSString*) path target:(id) target selector:(SEL) selector
{
	return [self playUrlAsync:[[IphoneAudioSupport sharedInstance] urlForPath:path] target:target selector:selector];
}

- (bool) play
{
	if(suspended)
	{
		NSLog(@"Error: BackgroundAudio: Could not play: Audio is still suspended");
		return NO;
	}
	player.currentTime = 0;
	player.volume = gain;
	player.numberOfLoops = numberOfLoops;
	return [player play];
}

- (void) stop
{
	if(player.playing)
	{
		[player stop];
		player.currentTime = 0;
#if TARGET_IPHONE_SIMULATOR
		[self handleSimulatorEndPlaybackBug];
#endif /* TARGET_IPHONE_SIMULATOR */
	}
	paused = NO;
	wasPlaying = NO;
}

- (void) clear
{
	[currentlyLoadedUrl release];
	currentlyLoadedUrl = nil;
	[player release];
	player = nil;
}


#pragma mark Internal Utility

- (void) checkForError:(OSStatus) errorCode
{
	switch(errorCode)
	{
		case kAudioSessionNoError:
			break;
		case kAudioSessionNotInitialized:
			NSLog(@"Error: BackgroundAudio: Session not initialized (error code %x)", errorCode);
			break;
		case kAudioSessionAlreadyInitialized:
			NSLog(@"Error: BackgroundAudio: Session already initialized (error code %x)", errorCode);
			break;
		case kAudioSessionInitializationError:
			NSLog(@"Error: BackgroundAudio: Sesion initialization error (error code %x)", errorCode);
			break;
		case kAudioSessionUnsupportedPropertyError:
			NSLog(@"Error: BackgroundAudio: Unsupported session property (error code %x)", errorCode);
			break;
		case kAudioSessionBadPropertySizeError:
			NSLog(@"Error: BackgroundAudio: Bad session property size (error code %x)", errorCode);
			break;
		case kAudioSessionNotActiveError:
			NSLog(@"Error: BackgroundAudio: Session is not active (error code %x)", errorCode);
			break;
#if 0 // Documented but not implemented on iPhone
		case kAudioSessionNoHardwareError:
			NSLog(@"Error: BackgroundAudio: Hardware not available for session (error code %x)", errorCode);
			break;
#endif
#ifdef __IPHONE_3_1
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1
		case kAudioSessionNoCategorySet:
			NSLog(@"Error: BackgroundAudio: No session category set (error code %x)", errorCode);
			break;
		case kAudioSessionIncompatibleCategory:
			NSLog(@"Error: BackgroundAudio: Incompatible session category (error code %x)", errorCode);
			break;
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1 */
#endif /* __IPHONE_3_1 */
		default:
			NSLog(@"Error: BackgroundAudio: Unknown session error (error code %x)", errorCode);
	}
}

- (UInt32) getIntProperty:(AudioSessionPropertyID) property
{
	UInt32 value;
	UInt32 size = sizeof(value);
	[self checkForError:AudioSessionGetProperty(property, &size, &value)];
	return value;
}

- (void) setIntProperty:(AudioSessionPropertyID) property value:(UInt32) value
{
	[self checkForError:AudioSessionSetProperty(property, sizeof(value), &value)];
}

- (void) updateAudioMode
{
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
}


#pragma mark Metering

- (bool) meteringEnabled
{
	return meteringEnabled;
}

- (void) setMeteringEnabled:(bool) value
{
	meteringEnabled = value;
	player.meteringEnabled = meteringEnabled;
}

- (void) updateMeters
{
	[player updateMeters];
}

- (float) averagePowerForChannel:(NSUInteger)channelNumber
{
	return [player averagePowerForChannel:channelNumber];
}

- (float) peakPowerForChannel:(NSUInteger)channelNumber
{
	return [player peakPowerForChannel:channelNumber];
}


#pragma mark Internal Use

@synthesize suspended;

- (void) setSuspended:(bool) value
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


#pragma mark -
#pragma mark Simulator playback bug handler

#if TARGET_IPHONE_SIMULATOR
- (void) audioPlayerBeginInterruption:(AVAudioPlayer*) playerIn
{
	[delegate audioPlayerBeginInterruption:playerIn];
}

- (void) audioPlayerEndInterruption:(AVAudioPlayer*) playerIn
{
	[delegate audioPlayerEndInterruption:playerIn];
}

- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*) playerIn error:(NSError*) error
{
	[delegate audioPlayerDecodeErrorDidOccur:playerIn error:error];
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer*) playerIn successfully:(BOOL) flag
{
	[self handleSimulatorEndPlaybackBug];
	[delegate audioPlayerDidFinishPlaying:playerIn successfully:flag];
}

- (void) handleSimulatorEndPlaybackBug
{
	player.volume = 0;
	player.numberOfLoops = -1;
	[player play];
}
#endif /* TARGET_IPHONE_SIMULATOR */

@end
