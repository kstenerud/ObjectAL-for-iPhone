//
//  OALActionManager.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-18.
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

#import "OALActionManager.h"
#import "mach_timing.h"

#if !OBJECTAL_USE_COCOS2D_ACTIONS


#pragma mark OALActionManager

@implementation OALActionManager


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALActionManager);

- (id) init
{
	if(nil != (self = [super init]))
	{
		targets = [[NSMutableArray arrayWithCapacity:50] retain];
		targetActions = [[NSMutableArray arrayWithCapacity:50] retain];
		actionsToAdd = [[NSMutableArray arrayWithCapacity:100] retain];
		actionsToRemove = [[NSMutableArray arrayWithCapacity:100] retain];
	}
	return self;
}

- (void) dealloc
{
	[targets release];
	[targetActions release];
	[actionsToAdd release];
	[actionsToRemove release];
	[super dealloc];
}


#pragma mark Action Management

- (void) stopAllActions
{
	for(NSMutableArray* actions in targetActions)
	{
		[actions makeObjectsPerformSelector:@selector(stop)];
	}

	[actionsToAdd makeObjectsPerformSelector:@selector(stop)];
}


#pragma mark Timer Interface

- (void) step:(NSTimer*) timer
{
	// Add new actions
	for(OALAction* action in actionsToAdd)
	{
		if(action.running)
		{
			NSUInteger index = [targets indexOfObject:action.target];
			if(NSNotFound == index)
			{
				index = [targets count];
				[targets addObject:action.target];
				[targetActions addObject:[NSMutableArray arrayWithCapacity:5]];
			}
			NSMutableArray* actions = [targetActions objectAtIndex:index];
			[actions addObject:action];
		}
	}
	[actionsToAdd removeAllObjects];

	// Remove stopped actions
	for(OALAction* action in actionsToRemove)
	{
		NSUInteger index = [targets indexOfObject:action.target];
		if(NSNotFound != index)
		{
			NSMutableArray* actions = [targetActions objectAtIndex:index];
			[actions removeObject:action];
			if([actions count] == 0)
			{
				[targets removeObjectAtIndex:index];
				[targetActions removeObjectAtIndex:index];

				// If there are no more actions running, stop the timer.
				if([targets count] == 0)
				{
					[stepTimer invalidate];
					stepTimer = nil;
				}
			}
		}
	}
	[actionsToRemove removeAllObjects];
	
	// Update all remaining actions, if any
	uint64_t currentTime = mach_absolute_time();
	for(NSMutableArray* actions in targetActions)
	{
		for(OALAction* action in actions)
		{
			float elapsedTime = mach_absolute_difference_seconds(currentTime, action.startTime);
			float proportionComplete = elapsedTime / action.duration;
			if(proportionComplete > 1.0)
			{
				proportionComplete = 1.0;
			}
			[action update:proportionComplete];
			if(1.0 == proportionComplete)
			{
				[action stop];
			}
		}
	}
}


#pragma mark Internal Use

- (void) notifyActionStarted:(OALAction*) action
{
	[actionsToAdd addObject:action];
	
	// Only start the timer if there are actions to perform.
	if([targets count] == 0)
	{
		stepTimer = [NSTimer scheduledTimerWithTimeInterval:kActionStepInterval
													 target:self
												   selector:@selector(step:)
												   userInfo:nil
													repeats:YES];
	}
}

- (void) notifyActionStopped:(OALAction*) action
{
	[actionsToRemove addObject:action];
}

@end

#endif /* OBJECTAL_USE_COCOS2D_ACTIONS */
