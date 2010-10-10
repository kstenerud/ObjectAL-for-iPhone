//
//  OALSimpleAudio.m
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

#import "OALSimpleAudio.h"
#import "ObjectALMacros.h"
#import "IOSAudioSupport.h"
#import "OpenALManager.h"

// By default, reserve all 32 sources.
#define kDefaultReservedSources 32

#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private interface to OALSimpleAudio.
 */
@interface OALSimpleAudio (Private)

/** (INTERNAL USE) Preload a sound effect and return the preloaded buffer.
 *
 * @param filePath The path containing the sound data.
 * @return The preloaded buffer.
 */
- (ALBuffer*) internalPreloadEffect:(NSString*) filePath;

@end

#pragma mark -
#pragma mark OALSimpleAudio

@implementation OALSimpleAudio

#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALSimpleAudio);


+ (OALSimpleAudio*) sharedInstanceWithSources:(int) sources
{
	return [[[self alloc] initWithSources:sources] autorelease];
}

- (id) init
{
	return [self initWithSources:kDefaultReservedSources];
}

- (id) initWithSources:(int) sources
{
	if(nil != (self = [super init]))
	{
		device = [[ALDevice deviceWithDeviceSpecifier:nil] retain];
		context = [[ALContext contextOnDevice:device attributes:nil] retain];
		[OpenALManager sharedInstance].currentContext = context;
		channel = [[ALChannelSource channelWithSources:sources] retain];

		backgroundTrack = [[OALAudioTrack track] retain];

		self.preloadCacheEnabled = YES;
		self.bgVolume = 1.0;
		self.effectsVolume = 1.0;
	}
	return self;
}

- (void) dealloc
{
	[backgroundTrack release];
	[channel stop];
	[channel release];
	[preloadCache release];
	[context release];
	[device release];
	
	[super dealloc];
}

#pragma mark Properties

- (NSUInteger) preloadCacheCount
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [preloadCache count];
	}
}

- (bool) preloadCacheEnabled
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return nil != preloadCache;
	}
}

- (void) setPreloadCacheEnabled:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(value != self.preloadCacheEnabled)
		{
			if(value)
			{
				preloadCache = [[NSMutableDictionary dictionaryWithCapacity:50] retain];
			}
			else
			{
				[preloadCache release];
				preloadCache = nil;
			}
		}
	}
}

- (bool) allowIpod
{
	return [IOSAudioSupport sharedInstance].allowIpod;
}

- (void) setAllowIpod:(bool) value
{
	[IOSAudioSupport sharedInstance].allowIpod = value;
}

- (bool) useHardwareIfAvailable
{
	return [IOSAudioSupport sharedInstance].useHardwareIfAvailable;
}

- (void) setUseHardwareIfAvailable:(bool) value
{
	[IOSAudioSupport sharedInstance].useHardwareIfAvailable = value;
}

@synthesize backgroundTrack;

- (bool) bgPaused
{
	return backgroundTrack.paused;
}

- (void) setBgPaused:(bool) value
{
	backgroundTrack.paused = value;
}

- (bool) bgPlaying
{
	return backgroundTrack.playing;
}

- (float) bgVolume
{
	return backgroundTrack.gain;
}

- (void) setBgVolume:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		backgroundTrack.gain = value;
	}
}

- (bool) effectsPaused
{
	return channel.paused;
}

- (void) setEffectsPaused:(bool) value
{
	channel.paused = value;
}

- (float) effectsVolume
{
	return [OpenALManager sharedInstance].currentContext.listener.gain;
}

- (void) setEffectsVolume:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[OpenALManager sharedInstance].currentContext.listener.gain = value;
	}
}

- (bool) paused
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return self.effectsPaused && self.bgPaused;
	}
}

- (void) setPaused:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		self.effectsPaused = self.bgPaused = value;
	}
}

- (bool) honorSilentSwitch
{
	return [IOSAudioSupport sharedInstance].honorSilentSwitch;
}

- (void) setHonorSilentSwitch:(bool) value
{
	[IOSAudioSupport sharedInstance].honorSilentSwitch = value;
}

- (bool) bgMuted
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return bgMuted;
	}
}

- (void) setBgMuted:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		bgMuted = value;
		backgroundTrack.muted = bgMuted | muted;
	}
}

- (bool) effectsMuted
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return effectsMuted;
	}
}

- (void) setEffectsMuted:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		effectsMuted = value;
		[OpenALManager sharedInstance].currentContext.listener.muted = effectsMuted | muted;
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
		backgroundTrack.muted = bgMuted | muted;
		[OpenALManager sharedInstance].currentContext.listener.muted = effectsMuted | muted;
	}
}	

#pragma mark Background Music

- (bool) preloadBg:(NSString*) filePath
{
	if(nil == filePath)
	{
		LOG_ERROR(@"filePath was NULL");
		return NO;
	}
	return [backgroundTrack preloadFile:filePath];
}

- (bool) playBg:(NSString*) filePath
{
	return [self playBg:filePath loop:NO];
}

- (bool) playBg:(NSString*) filePath loop:(bool) loop
{
	if(nil == filePath)
	{
		LOG_ERROR(@"filePath was NULL");
		return NO;
	}
	return [backgroundTrack playFile:filePath loops:loop ? -1 : 0];
}

- (bool) playBg:(NSString*) filePath
		 volume:(float) volume
			pan:(float) pan
		   loop:(bool) loop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		backgroundTrack.gain = volume;
		backgroundTrack.pan = pan;
		backgroundTrack.numberOfLoops = loop ? -1 : 0;
		return [backgroundTrack play];
	}
}

- (bool) playBg
{
	return [self playBgWithLoop:NO];
}

- (bool) playBgWithLoop:(bool) loop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		backgroundTrack.numberOfLoops = loop ? -1 : 0;
		return [backgroundTrack play];
	}
}

- (void) stopBg
{
	[backgroundTrack stop];
}


#pragma mark Sound Effects

- (ALBuffer*) internalPreloadEffect:(NSString*) filePath
{
	ALBuffer* buffer;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		buffer = [preloadCache objectForKey:filePath];
	}
	if(nil == buffer)
	{
		buffer = [[IOSAudioSupport sharedInstance] bufferFromFile:filePath];
		if(nil == buffer)
		{
			LOG_ERROR(@"Could not load effect %@", filePath);
			return nil;
		}

		OPTIONALLY_SYNCHRONIZED(self)
		{
			[preloadCache setObject:buffer forKey:filePath];
		}
	}

	return buffer;
}

- (void) preloadEffect:(NSString*) filePath
{
	if(nil == filePath)
	{
		LOG_ERROR(@"filePath was NULL");
		return;
	}
	[self internalPreloadEffect:filePath];
}

- (void) unloadEffect:(NSString*) filePath
{
	if(nil == filePath)
	{
		LOG_ERROR(@"filePath was NULL");
		return;
	}
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[preloadCache removeObjectForKey:filePath];
	}
}

- (void) unloadAllEffects
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[preloadCache removeAllObjects];
	}
}

- (id<ALSoundSource>) playEffect:(NSString*) filePath
{
	return [self playEffect:filePath volume:1.0 pitch:1.0 pan:0.0 loop:NO];
}

- (id<ALSoundSource>) playEffect:(NSString*) filePath loop:(bool) loop
{
	return [self playEffect:filePath volume:1.0 pitch:1.0 pan:0.0 loop:loop];
}

- (id<ALSoundSource>) playEffect:(NSString*) filePath
						  volume:(float) volume
						   pitch:(float) pitch
							 pan:(float) pan
							loop:(bool) loop
{
	if(nil == filePath)
	{
		LOG_ERROR(@"filePath was NULL");
		return NO;
	}
	ALBuffer* buffer = [self internalPreloadEffect:filePath];
	if(nil != buffer)
	{
		return [channel play:buffer gain:volume pitch:pitch pan:pan loop:loop];
	}
	return nil;
}

- (void) stopAllEffects
{
	[channel stop];
}


#pragma mark Utility

- (void) stopEverything
{
	[self stopAllEffects];
	[self stopBg];
}

@end
