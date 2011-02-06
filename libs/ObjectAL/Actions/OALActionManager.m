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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALActionManager.h"
#import "mach_timing.h"
#import "ObjectALMacros.h"
#import "NSMutableArray+WeakReferences.h"
#import "IOSVersion.h"
#import <UIKit/UIKit.h>

#if !OBJECTAL_USE_COCOS2D_ACTIONS

SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(OALActionManager);

/**
 * (INTERNAL USE) Private methods for OALActionManager.
 */
@interface OALActionManager (Private)

/** Resets the time delta in cases where proper time delta calculations become impossible.
 */
- (void) doResetTimeDelta:(NSNotification*) notification;

@end

#pragma mark OALActionManager

@implementation OALActionManager


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALActionManager);

- (id) init
{
	if(nil != (self = [super init]))
	{
		targets = [NSMutableArray newMutableArrayUsingWeakReferencesWithCapacity:50];
		targetActions = [[NSMutableArray alloc] initWithCapacity:50];
		actionsToAdd = [[NSMutableArray alloc] initWithCapacity:100];
		actionsToRemove = [[NSMutableArray alloc] initWithCapacity:100];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(doResetTimeDelta:)
													 name:UIApplicationSignificantTimeChangeNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(doResetTimeDelta:)
													 name:UIApplicationDidBecomeActiveNotification
												   object:nil];
		if([IOSVersion sharedInstance].version >= 4.0)
		{
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(doResetTimeDelta:)
														 name:@"UIApplicationWillEnterForegroundNotification"
													   object:nil];
		}
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[targets release];
	[targetActions release];
	[actionsToAdd release];
	[actionsToRemove release];
	[super dealloc];
}

- (void) doResetTimeDelta:(NSNotification*) notification
{
	lastTimestamp = 0;
}


#pragma mark Action Management

- (void) stopAllActions
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		for(NSMutableArray* actions in targetActions)
		{
			[actions makeObjectsPerformSelector:@selector(stopAction)];
		}
		
		[actionsToAdd makeObjectsPerformSelector:@selector(stopAction)];
	}
}


#pragma mark Timer Interface

- (void) step:(NSTimer*) timer
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		// Add new actions
		for(OALAction* action in actionsToAdd)
		{
			// But only if they haven't been stopped already
			if(action.running)
			{
				NSUInteger index = [targets indexOfObject:action.target];
				if(NSNotFound == index)
				{
					// Since this target has no running actions yet, add the support
					// structure to keep track of it.
					index = [targets count];
					[targets addObject:action.target];
					[targetActions addObject:[NSMutableArray arrayWithCapacity:5]];
				}

				// Get the list of actions operating on this target and add the new action.
				NSMutableArray* actions = [targetActions objectAtIndex:index];
				[actions addObject:action];
			}
		}
		// All actions have been added.  Clear the "add" list.
		[actionsToAdd removeAllObjects];
		

		// Remove stopped actions
		for(OALAction* action in actionsToRemove)
		{
			NSUInteger index = [targets indexOfObject:action.target];
			if(NSNotFound != index)
			{
				// Remove the action.
				NSMutableArray* actions = [targetActions objectAtIndex:index];
				[actions removeObject:action];
				if([actions count] == 0)
				{
					// If there are no more actions for this target, stop tracking it.
					[targets removeObjectAtIndex:index];
					[targetActions removeObjectAtIndex:index];
					
					// If there are no more actions running, stop the master timer.
					if([targets count] == 0)
					{
						[stepTimer invalidate];
						stepTimer = nil;
						break;
					}
				}
			}
		}
		[actionsToRemove removeAllObjects];
		
		// Get the time elapsed and update timestamp.
		// If there was a break in timing (lastTimestamp == 0), assume 0 time has elapsed.
		uint64_t currentTime = mach_absolute_time();
		float elapsedTime = 0;
		if(lastTimestamp > 0)
		{
			elapsedTime = (float)mach_absolute_difference_seconds(currentTime, lastTimestamp);
		}
		lastTimestamp = currentTime;

		// Update all remaining actions, if any
		for(NSMutableArray* actions in targetActions)
		{
			for(OALAction* action in actions)
			{
				action.elapsed += elapsedTime;
				float proportionComplete = action.elapsed / action.duration;
				if(proportionComplete < 1.0f)
				{
					[action updateCompletion:proportionComplete];
				}
				else
				{
					[action updateCompletion:1.0f];
					[action stopAction];
				}
			}
		}
	}
}


#pragma mark Internal Use

- (void) notifyActionStarted:(OALAction*) action
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[actionsToAdd addObject:action];
		
		// Start the timer if it hasn't been started yet and there are actions to perform.
		if([targets count] == 0 && [actionsToAdd count] == 1)
		{
			stepTimer = [NSTimer scheduledTimerWithTimeInterval:kActionStepInterval
														 target:self
													   selector:@selector(step:)
													   userInfo:nil
														repeats:YES];

			// Reset timestamp since we have been off for awhile.
			lastTimestamp = 0;
		}
	}
}

- (void) notifyActionStopped:(OALAction*) action
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[actionsToRemove addObject:action];
	}
}

@end

#endif /* OBJECTAL_USE_COCOS2D_ACTIONS */
