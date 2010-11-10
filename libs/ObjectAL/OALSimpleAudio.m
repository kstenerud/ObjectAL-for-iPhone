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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALSimpleAudio.h"
#import "ObjectALMacros.h"
#import "OALAudioSupport.h"
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
		
#if NS_BLOCKS_AVAILABLE && OBJECTAL_USE_BLOCKS
		oal_dispatch_queue	= dispatch_queue_create("objectal.simpleaudio.queue", NULL);
#endif
		pendingLoadCount	= 0;

		self.preloadCacheEnabled = YES;
		self.bgVolume = 1.0f;
		self.effectsVolume = 1.0f;
	}
	return self;
}

- (void) dealloc
{
#if NS_BLOCKS_AVAILABLE && OBJECTAL_USE_BLOCKS
	dispatch_release(oal_dispatch_queue);
#endif
	
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
				preloadCache = [[NSMutableDictionary alloc] initWithCapacity:64];
			}
			else
			{
				if(pendingLoadCount > 0)
				{
					OAL_LOG_WARNING(@"attempted to turn off preload cache while pending loads are queued.");
					return;
				}
				else
				{
					[preloadCache release];
					preloadCache = nil;
				}
			}
		}
	}
}

- (bool) allowIpod
{
	return [OALAudioSupport sharedInstance].allowIpod;
}

- (void) setAllowIpod:(bool) value
{
	[OALAudioSupport sharedInstance].allowIpod = value;
}

- (bool) useHardwareIfAvailable
{
	return [OALAudioSupport sharedInstance].useHardwareIfAvailable;
}

- (void) setUseHardwareIfAvailable:(bool) value
{
	[OALAudioSupport sharedInstance].useHardwareIfAvailable = value;
}


- (unsigned int) reservedSources
{
	return channel.reservedSources;
}

- (void) setReservedSources:(unsigned int) value
{
	channel.reservedSources = value;
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
	return [OALAudioSupport sharedInstance].honorSilentSwitch;
}

- (void) setHonorSilentSwitch:(bool) value
{
	[OALAudioSupport sharedInstance].honorSilentSwitch = value;
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

- (NSURL *) backgroundTrackURL
{
	return [backgroundTrack currentlyLoadedUrl];
}

- (bool) preloadBg:(NSString*) filePath
{
	return [self preloadBg:filePath seekTime:0];
}

- (bool) preloadBg:(NSString*) filePath seekTime:(NSTimeInterval)seekTime
{
	if(nil == filePath)
	{
		OAL_LOG_ERROR(@"filePath was NULL");
		return NO;
	}
	BOOL result = [backgroundTrack preloadFile:filePath seekTime:seekTime];
	if(result){
		backgroundTrack.numberOfLoops = 0;
	}
	return result;
}

- (bool) playBg:(NSString*) filePath
{
	return [self playBg:filePath loop:NO];
}

- (bool) playBg:(NSString*) filePath loop:(bool) loop
{
	if(nil == filePath)
	{
		OAL_LOG_ERROR(@"filePath was NULL");
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
		return [backgroundTrack playFile:filePath loops:loop ? -1 : 0];
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
		buffer = [[OALAudioSupport sharedInstance] bufferFromFile:filePath];
		if(nil == buffer)
		{
			OAL_LOG_ERROR(@"Could not load effect %@", filePath);
			return nil;
		}

		OPTIONALLY_SYNCHRONIZED(self)
		{
			[preloadCache setObject:buffer forKey:filePath];
		}
	}

	return buffer;
}

- (ALBuffer*) preloadEffect:(NSString*) filePath
{
	if(nil == filePath)
	{
		OAL_LOG_ERROR(@"filePath was NULL");
		return nil;
	}
	if(pendingLoadCount > 0)
		OAL_LOG_WARNING(@"You are loading an effect synchronously, but have pending async loads that have not completed. Your load will happen after those finish. Your thread is now stuck waiting. Next time just load everything async please.");

#if NS_BLOCKS_AVAILABLE && OBJECTAL_USE_BLOCKS
	//Using blocks with the same queue used to asynch load removes the need for locking
	//BUT be warned that if you had called preloadEffects and then called this method, your app will stall until all of the loading is done.
	//It is advised you just always use async loading
	__block ALBuffer* retBuffer = nil;
	pendingLoadCount++;
	dispatch_sync(oal_dispatch_queue, ^{
		retBuffer = [self internalPreloadEffect:filePath];
	});
	pendingLoadCount--;
	return retBuffer;
#else
	return [self internalPreloadEffect:filePath];
#endif
}

#if NS_BLOCKS_AVAILABLE && OBJECTAL_USE_BLOCKS

- (BOOL) preloadEffect:(NSString*) filePath
			completionBlock:(void(^)(ALBuffer *)) completionBlock
{
	if(nil == filePath)
	{
		OAL_LOG_ERROR(@"filePath was NULL");
		completionBlock(nil);
		return NO;
	}
	
	pendingLoadCount++;
	dispatch_async(oal_dispatch_queue, ^{
		OAL_LOG_INFO(@"Preloading effect: %@", filePath);
		
		ALBuffer *retBuffer = [self internalPreloadEffect:filePath];
		if(!retBuffer)
		{
			 OAL_LOG_WARNING(@"%@ failed to preload.", filePath);
		}
		dispatch_async(dispatch_get_main_queue(),
		^{
			completionBlock(retBuffer);
			pendingLoadCount--;
		});
	});
	return YES;
}

- (void) preloadEffects:(NSArray*) filePaths
		  progressBlock:(void (^)(uint progress, uint successCount, uint total)) progressBlock
{
	uint total					= [filePaths count];
	if(total < 1)
	{
		OAL_LOG_ERROR(@"Preload effects: No files to process");
		progressBlock(0,0,0);
		return;
	}
	
	__block uint successCount	= 0;
	
	pendingLoadCount			+= total;
	dispatch_async(oal_dispatch_queue,
	^{
		[filePaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
		 {
			 OAL_LOG_INFO(@"Preloading effect: %@", obj);
			 ALBuffer *result = [self internalPreloadEffect:(NSString *)obj];
			 if(!result)
			 {
				 OAL_LOG_WARNING(@"%@ failed to preload.", obj);
			 }
			 else
			 {
				 successCount++;
			 }
			 uint cnt = idx+1;
			 dispatch_async(dispatch_get_main_queue(), 
			 ^{
				 if(cnt == total)
				 {
					 pendingLoadCount		-= total;
				 }
				 progressBlock(cnt, successCount, total);
			 });
		 }];
	});
}
#else
- (void) preloadEffects:(NSArray*) filePaths
	 progressInvocation:(NSInvocation *) progressInvocation
   completionInvocation:(NSInvocation *) completionInvocation
{
	
}
#endif

- (void) unloadEffect:(NSString*) filePath
{
	if(nil == filePath)
	{
		OAL_LOG_ERROR(@"filePath was NULL");
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
	return [self playEffect:filePath volume:1.0f pitch:1.0f pan:0.0f loop:NO];
}

- (id<ALSoundSource>) playEffect:(NSString*) filePath loop:(bool) loop
{
	return [self playEffect:filePath volume:1.0f pitch:1.0f pan:0.0f loop:loop];
}

- (id<ALSoundSource>) playEffect:(NSString*) filePath
						  volume:(float) volume
						   pitch:(float) pitch
							 pan:(float) pan
							loop:(bool) loop
{
	if(nil == filePath)
	{
		OAL_LOG_ERROR(@"filePath was NULL");
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

- (void) resetToDefault
{
	[self stopEverything];
	[channel resetToDefault];
	self.reservedSources = kDefaultReservedSources;
	self.bgMuted = NO;
	self.bgVolume = 1.0f;
}

@end
