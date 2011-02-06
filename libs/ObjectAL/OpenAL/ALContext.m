//
//  ALContext.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-01-09.
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

#import "ALContext.h"
#import "NSMutableArray+WeakReferences.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"
#import "OpenALManager.h"
#import "ALDevice.h"


#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private methods for ALContext.
 */
@interface ALContext (Private)

/** (INTERNAL USE) Close any resources belonging to the OS.
 */
- (void) closeOSResources;

/** (INTERNAL USE) Called by SuspendHandler.
 */
- (void) setSuspended:(bool) value;

@end


@implementation ALContext

#pragma mark Object Management

+ (id) contextOnDevice:(ALDevice *) device attributes:(NSArray*) attributes
{
	return [[[self alloc] initOnDevice:device attributes:attributes] autorelease];
}

+ (id) contextOnDevice:(ALDevice*) device
	   outputFrequency:(int) outputFrequency
	  refreshIntervals:(int) refreshIntervals 
	synchronousContext:(bool) synchronousContext
		   monoSources:(int) monoSources
		 stereoSources:(int) stereoSources
{
	NSMutableArray* attributes = [NSMutableArray arrayWithCapacity:5];
	if(outputFrequency > 0)
	{
		[attributes addObject:[NSNumber numberWithInt:ALC_FREQUENCY]];
		[attributes addObject:[NSNumber numberWithInt:outputFrequency]];
	}
	if(refreshIntervals > 0)
	{
		[attributes addObject:[NSNumber numberWithInt:ALC_REFRESH]];
		[attributes addObject:[NSNumber numberWithInt:refreshIntervals]];
	}
	[attributes addObject:[NSNumber numberWithInt:ALC_SYNC]];
	[attributes addObject:[NSNumber numberWithInt:synchronousContext ? AL_TRUE : AL_FALSE]];
	
	if(monoSources >= 0)
	{
		[attributes addObject:[NSNumber numberWithInt:ALC_MONO_SOURCES]];
		[attributes addObject:[NSNumber numberWithInt:monoSources]];
	}
	if(stereoSources >= 0)
	{
		[attributes addObject:[NSNumber numberWithInt:ALC_STEREO_SOURCES]];
		[attributes addObject:[NSNumber numberWithInt:stereoSources]];
	}
	
	return [self contextOnDevice:device attributes:attributes];
}

- (id) initOnDevice:(ALDevice*) deviceIn
	outputFrequency:(int) outputFrequency
   refreshIntervals:(int) refreshIntervals 
 synchronousContext:(bool) synchronousContext
		monoSources:(int) monoSources
	  stereoSources:(int) stereoSources
{
	NSMutableArray* attributesList = [NSMutableArray arrayWithCapacity:5];
	if(outputFrequency > 0)
	{
		[attributesList addObject:[NSNumber numberWithInt:ALC_FREQUENCY]];
		[attributesList addObject:[NSNumber numberWithInt:outputFrequency]];
	}
	if(refreshIntervals > 0)
	{
		[attributesList addObject:[NSNumber numberWithInt:ALC_REFRESH]];
		[attributesList addObject:[NSNumber numberWithInt:refreshIntervals]];
	}
	[attributesList addObject:[NSNumber numberWithInt:ALC_SYNC]];
	[attributesList addObject:[NSNumber numberWithInt:synchronousContext ? AL_TRUE : AL_FALSE]];
	
	if(monoSources >= 0)
	{
		[attributesList addObject:[NSNumber numberWithInt:ALC_MONO_SOURCES]];
		[attributesList addObject:[NSNumber numberWithInt:monoSources]];
	}
	if(stereoSources >= 0)
	{
		[attributesList addObject:[NSNumber numberWithInt:ALC_STEREO_SOURCES]];
		[attributesList addObject:[NSNumber numberWithInt:stereoSources]];
	}
	
	return [self initOnDevice:deviceIn attributes:attributes];
}

- (id) initOnDevice:(ALDevice *) deviceIn attributes:(NSArray*) attributesIn
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init on %@ with attributes 0x%08x", self, deviceIn, attributesIn);

		if(nil == deviceIn)
		{
			OAL_LOG_ERROR(@"%@: Failed to init because device was nil. Returning nil", self);
			[self release];
			return nil;
		}

		suspendHandler = [[OALSuspendHandler alloc] initWithTarget:self selector:@selector(setSuspended:)];

		// Build up an ALCint array for OpenAL's createContext function.
		ALCint* attributesList = nil;

		if([attributesIn count] > 0)
		{
			attributesList = (ALCint*)malloc(sizeof(ALCint) * [attributesIn count]);
			ALCint* attributePtr = attributesList;
			for(NSNumber* number in attributesIn)
			{
				*attributePtr++ = [number intValue];
			}
		}
		
		// Notify the device that we are being created.
		device = [deviceIn retain];
		[device notifyContextInitializing:self];

		// Open the context with our list of attributes.
		context = [ALWrapper createContext:device.device attributes:attributesList];
		
		listener = [[ALListener alloc] initWithContext:self];
		
		sources = [NSMutableArray newMutableArrayUsingWeakReferencesWithCapacity:32];
		
		// Cache all attributes for this context.
		attributes = [[NSMutableArray alloc] initWithCapacity:5];
		int buffSize = [ALWrapper getInteger:device.device attribute:ALC_ATTRIBUTES_SIZE];
		if(buffSize > 0)
		{
			if(nil != attributesList)
			{
				free(attributesList);
			}
			attributesList = malloc(sizeof(ALCint) * buffSize);
			if([ALWrapper getIntegerv:device.device attribute:ALC_ALL_ATTRIBUTES size:buffSize data:attributesList])
			{
				for(int i = 0; i < buffSize; i++)
				{
					[attributes addObject:[NSNumber numberWithInt:attributesList[i]]];
				}
			}
		}

		if(nil != attributesList)
		{
			free(attributesList);
		}

		// Manually add a suspend listener for ALListener because if someone
		// retains the listener it could outlive the context, even though
		// such a thing would be bad form.
		[self addSuspendListener:listener];

		[device addSuspendListener:self];
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);

	[self removeSuspendListener:listener];
	[device removeSuspendListener:self];
	[device notifyContextDeallocating:self];

	[self closeOSResources];
	
	[sources release];
	[listener release];
	[device release];
	[attributes release];
	[suspendHandler release];

	[super dealloc];
}

- (void) closeOSResources
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(nil != context)
		{
			if([OpenALManager sharedInstance].currentContext == self)
			{
				[OpenALManager sharedInstance].currentContext = nil;
			}
			[ALWrapper destroyContext:context];
			context = nil;
		}
	}
}

- (void) close
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(nil != context)
		{
			[sources makeObjectsPerformSelector:@selector(close)];
			[sources release];
			sources = nil;
			
			[self closeOSResources];
		}
	}
}


#pragma mark Properties

- (NSString*) alVersion
{
	return [ALWrapper getString:AL_VERSION];
}

@synthesize attributes;

@synthesize context;

@synthesize device;

- (ALenum) distanceModel
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getInteger:AL_DISTANCE_MODEL];
	}
}

- (void) setDistanceModel:(ALenum) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper distanceModel:value];
	}
}

- (float) dopplerFactor
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getFloat:AL_DOPPLER_FACTOR];
	}
}

- (void) setDopplerFactor:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper dopplerFactor:value];
	}
}

- (NSArray*) extensions
{
	return [ALWrapper getSpaceSeparatedStringList:AL_EXTENSIONS];
}

@synthesize listener;

- (NSString*) renderer
{
	return [ALWrapper getString:AL_RENDERER];
}

@synthesize sources;

- (float) speedOfSound
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getFloat:AL_SPEED_OF_SOUND];
	}
}

- (void) setSpeedOfSound:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper speedOfSound:value];
	}
}

- (NSString*) vendor
{
	return [ALWrapper getString:AL_VENDOR];
}


#pragma mark Suspend Handler

- (void) addSuspendListener:(id<OALSuspendListener>) listenerIn
{
	[suspendHandler addSuspendListener:listenerIn];
}

- (void) removeSuspendListener:(id<OALSuspendListener>) listenerIn
{
	[suspendHandler removeSuspendListener:listenerIn];
}

- (bool) manuallySuspended
{
	return suspendHandler.manuallySuspended;
}

- (void) setManuallySuspended:(bool) value
{
	suspendHandler.manuallySuspended = value;
}

- (bool) interrupted
{
	return suspendHandler.interrupted;
}

- (void) setInterrupted:(bool) value
{
	suspendHandler.interrupted = value;
}

- (bool) suspended
{
	return suspendHandler.suspended;
}

- (void) setSuspended:(bool) value
{
	if(value)
	{
		[ALWrapper suspendContext:context];
	}
	else
	{
		[self process];
	}
}


#pragma mark Utility

- (void) clearBuffers
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		for(ALSource* source in sources)
		{
			[source clear];
		}
	}
}

- (void) process
{
	if(self.suspended)
	{
		OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
		return;
	}
	
	[ALWrapper processContext:context];
}

- (void) stopAllSounds
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		for(ALSource* source in sources)
		{
			[source stop];
		}
	}
}

- (void) ensureContextIsCurrent
{
	if(self.suspended)
	{
		OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
		return;
	}
	
	if([ALWrapper getCurrentContext] != context)
	{
		[OpenALManager sharedInstance].currentContext = self;
	}
}

#pragma mark Extensions

- (bool) isExtensionPresent:(NSString*) name
{
	return [ALWrapper isExtensionPresent:name];
}

- (void*) getProcAddress:(NSString*) functionName
{
	return [ALWrapper getProcAddress:functionName];
}


#pragma mark Internal Use

- (void) notifySourceInitializing:(ALSource*) source
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[sources addObject:source];
	}
}

- (void) notifySourceDeallocating:(ALSource*) source
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[sources removeObject:source];
	}
}


@end
