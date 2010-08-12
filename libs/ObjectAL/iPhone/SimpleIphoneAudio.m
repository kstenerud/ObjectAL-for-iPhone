//
//  SimpleAudio.m
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

#import "SimpleIphoneAudio.h"
#import "ObjectALMacros.h"
#import "BackgroundAudio.h"
#import "IphoneAudioSupport.h"

// By default, reserve all 32 sources.
#define kDefaultReservedSources 32

#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private interface to SimpleIphoneAudio.
 */
@interface SimpleIphoneAudio (Private)

/** (INTERNAL USE) Preload a sound effect and return the preloaded buffer.
 *
 * @param filePath The path containing the sound data.
 * @return The preloaded buffer.
 */
- (ALBuffer*) internalPreloadEffect:(NSString*) filePath;

@end

#pragma mark -
#pragma mark SimpleIphoneAudio

@implementation SimpleIphoneAudio

#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(SimpleIphoneAudio);


+ (SimpleIphoneAudio*) sharedInstanceWithSources:(int) sources
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
		[ObjectAL sharedInstance].currentContext = context;
		
		[IphoneAudioSupport sharedInstance].handleInterruptions = YES;
		
		channel = [[ChannelSource channelWithSources:sources] retain];
		
		self.preloadCacheEnabled = YES;
		self.bgVolume = 1.0;
		self.effectsVolume = 1.0;

		[BackgroundAudio sharedInstance];
	}
	return self;
}

- (void) dealloc
{
	[[BackgroundAudio sharedInstance] clear];
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
	SYNCHRONIZED_OP(self)
	{
		return [preloadCache count];
	}
}

- (bool) preloadCacheEnabled
{
	SYNCHRONIZED_OP(self)
	{
		return nil != preloadCache;
	}
}

- (void) setPreloadCacheEnabled:(bool) value
{
	SYNCHRONIZED_OP(self)
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
	return [BackgroundAudio sharedInstance].allowIpod;
}

- (void) setAllowIpod:(bool) value
{
	[BackgroundAudio sharedInstance].allowIpod = value;
}

- (bool) bgPaused
{
	return [BackgroundAudio sharedInstance].paused;
}

- (void) setBgPaused:(bool) value
{
	[BackgroundAudio sharedInstance].paused = value;
}

- (bool) bgPlaying
{
	return [BackgroundAudio sharedInstance].playing;
}

- (float) bgVolume
{
	return [BackgroundAudio sharedInstance].gain;
}

- (void) setBgVolume:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[BackgroundAudio sharedInstance].gain = value;
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
	return [ObjectAL sharedInstance].currentContext.listener.gain;
}

- (void) setEffectsVolume:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ObjectAL sharedInstance].currentContext.listener.gain = value;
	}
}

- (bool) paused
{
	SYNCHRONIZED_OP(self)
	{
		return self.effectsPaused && self.bgPaused;
	}
}

- (void) setPaused:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		self.effectsPaused = self.bgPaused = value;
	}
}

- (bool) honorSilentSwitch
{
	return [BackgroundAudio sharedInstance].honorSilentSwitch;
}

- (void) setHonorSilentSwitch:(bool) value
{
	[BackgroundAudio sharedInstance].honorSilentSwitch = value;
}

- (bool) bgMuted
{
	SYNCHRONIZED_OP(self)
	{
		return bgMuted;
	}
}

- (void) setBgMuted:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		bgMuted = value;
		[BackgroundAudio sharedInstance].muted = bgMuted | muted;
	}
}

- (bool) effectsMuted
{
	SYNCHRONIZED_OP(self)
	{
		return effectsMuted;
	}
}

- (void) setEffectsMuted:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		effectsMuted = value;
		[ObjectAL sharedInstance].currentContext.listener.muted = effectsMuted | muted;
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
		[BackgroundAudio sharedInstance].muted = bgMuted | muted;
		[ObjectAL sharedInstance].currentContext.listener.muted = effectsMuted | muted;
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
	return [[BackgroundAudio sharedInstance] preloadFile:filePath];
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
	return [[BackgroundAudio sharedInstance] playFile:filePath loops:loop ? -1 : 0];
}

- (bool) playBg
{
	return [self playBgWithLoop:NO];
}

- (bool) playBgWithLoop:(bool) loop
{
	SYNCHRONIZED_OP(self)
	{
		[BackgroundAudio sharedInstance].numberOfLoops = loop ? -1 : 0;
		return [[BackgroundAudio sharedInstance] play];
	}
}

- (void) stopBg
{
	[[BackgroundAudio sharedInstance] stop];
}


#pragma mark Sound Effects

- (ALBuffer*) internalPreloadEffect:(NSString*) filePath
{
	ALBuffer* buffer;
	SYNCHRONIZED_OP(self)
	{
		buffer = [preloadCache objectForKey:filePath];
	}
	if(nil == buffer)
	{
		buffer = [[IphoneAudioSupport sharedInstance] bufferFromFile:filePath];
		if(nil == buffer)
		{
			LOG_ERROR(@"Could not load effect %@", filePath);
			return nil;
		}

		SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		[preloadCache removeObjectForKey:filePath];
	}
}

- (void) unloadAllEffects
{
	SYNCHRONIZED_OP(self)
	{
		[preloadCache removeAllObjects];
	}
}

- (id<SoundSource>) playEffect:(NSString*) filePath
{
	return [self playEffect:filePath volume:1.0 pitch:1.0 pan:0.0 loop:NO];
}

- (id<SoundSource>) playEffect:(NSString*) filePath loop:(bool) loop
{
	return [self playEffect:filePath volume:1.0 pitch:1.0 pan:0.0 loop:loop];
}

- (id<SoundSource>) playEffect:(NSString*) filePath volume:(float) volume pitch:(float) pitch pan:(float) pan loop:(bool) loop
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
