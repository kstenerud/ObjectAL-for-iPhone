//
//  SoundSourcePool.m
//  ObjectAL
//
//  Created by Karl Stenerud on 17/12/09.
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

#import "SoundSourcePool.h"
#import "ObjectALMacros.h"


#pragma mark Private Methods

/**
 * Private interface to SoundSourcePool.
 */
@interface SoundSourcePool (Private)

/** Move a source to the head of the list.
 *
 * @param index the index of the source to move.
 */
- (void) moveToHead:(int) index;

@end


#pragma mark -
#pragma mark SoundSourcePool

@implementation SoundSourcePool

#pragma mark Object Management

+ (id) pool
{
	return [[[self alloc] init] autorelease];
}

- (id) init
{
	if(nil != (self = [super init]))
	{
		sources = [[NSMutableArray arrayWithCapacity:10] retain];
	}
	return self;
}

- (void) dealloc
{
	[sources release];
	[super dealloc];
}


#pragma mark Properties

@synthesize sources;


#pragma mark Source Management

- (void) addSource:(id<SoundSource>) source
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[sources addObject:source];
	}
}

- (void) removeSource:(id<SoundSource>) source
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[sources removeObject:source];
	}
}

- (void) moveToHead:(int) index
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		id source = [[sources objectAtIndex:index] retain];
		[sources removeObjectAtIndex:index];
		[sources addObject:source];
		[source release];
	}
}

- (id<SoundSource>) getFreeSource:(bool) attemptToInterrupt
{
	int index = 0;
	
	OPTIONALLY_SYNCHRONIZED(self)
	{
		// Try to find any free source.
		for(id<SoundSource> source in sources)
		{
			if(!source.playing)
			{
				[self moveToHead:index];
				return source;
			}
			index++;
		}
		
		if(attemptToInterrupt)
		{
			// Try to forcibly free a source.
			index = 0;
			for(id<SoundSource> source in sources)
			{
				if(!source.playing || source.interruptible)
				{
					[source stop];
					[self moveToHead:index];
					return source;
				}
				index++;
			}
		}
	}		
	return nil;
}

@end
