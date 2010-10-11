//
//  OALUtilityActions.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-10.
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

#import "OALUtilityActions.h"


#pragma mark OALTargetedAction

@implementation OALTargetedAction


#pragma mark Object Management

+ (id) actionWithTarget:(id) target action:(OALAction*) action
{
	return [[[self alloc] initWithTarget:target action:action] autorelease];
}

- (id) initWithTarget:(id) targetIn action:(OALAction*) actionIn
{
	if(nil != (self = [super initWithDuration:actionIn.duration]))
	{
		forcedTarget = targetIn; // Weak reference
		action = [actionIn retain];
	}
	return self;
}

- (void) dealloc
{
	[action release];
	[super dealloc];
}


#pragma mark Properties

@synthesize forcedTarget;


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{
	[super prepareWithTarget:forcedTarget];
	[action prepareWithTarget:forcedTarget];
}

- (void) start
{
	[super start];
	[action start];
}

- (void) stop
{
	[super stop];
	[action stop];
}

- (void) update:(float) proportionComplete
{
	[super update:proportionComplete];
	[action update:proportionComplete];
}

@end


#if !OBJECTAL_USE_COCOS2D_ACTIONS

#pragma mark -
#pragma mark OALSequentialActions

@implementation OALSequentialActions


#pragma mark Object Management

+ (id) actions:(OALAction*) firstAction, ...
{
	NSMutableArray* actions = [NSMutableArray arrayWithCapacity:10];
	va_list params;
	va_start(params, firstAction);
	OALAction* action = firstAction;
	
	while(nil != action)
	{
		[actions addObject:action];
		action = va_arg(params,OALAction*);
	}
	
	va_end(params);
	
	return [[[self alloc] initWithActions:actions] autorelease];
}

+ (id) actionsFromArray:(NSArray*) actions;
{
	return [[[self alloc] initWithActions:actions] autorelease];
}

- (id) initWithActions:(NSArray*) actionsIn
{
	if(nil != (self = [super initWithDuration:0]))
	{
		if([actionsIn isKindOfClass:[NSMutableArray class]])
		{
			actions = [actionsIn retain];
		}
		else
		{
			actions = [[NSMutableArray arrayWithArray:actionsIn] retain];
		}
		
		pDurations = [[NSMutableArray arrayWithCapacity:[actions count]] retain];
	}
	return self;
}

- (void) dealloc
{
	[actions release];
	[pDurations release];
	[super dealloc];
}


#pragma mark Properties

@synthesize actions;


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{
	// Calculate the total duration in seconds of all children.
	duration = 0;
	for(OALAction* action in actions)
	{
		[action prepareWithTarget:targetIn];
		duration += action.duration;
	}
	
	// Calculate the childrens' duration as proportions of the total.
	[pDurations removeAllObjects];
	if(0 == duration)
	{
		for(OALAction* action in actions)
		{
			[pDurations addObject:[NSNumber numberWithFloat:0]];
		}
	}
	else
	{
		for(OALAction* action in actions)
		{
			[pDurations addObject:[NSNumber numberWithFloat:action.duration/duration]];
		}
	}
	
	// Start at the first action.
	if([actions count] > 0)
	{
		currentAction = [actions objectAtIndex:0];
		pCurrentActionDuration = [[pDurations objectAtIndex:0] floatValue];
	}
	else
	{
		// Just in case this is an empty set.
		currentAction = nil;
		pCurrentActionDuration = 0;
	}
	
	actionIndex = 0;
	pLastComplete = 0;
	pCurrentActionComplete = 0;
	
	[super prepareWithTarget:targetIn];
}

- (void) start
{
	[currentAction start];
	[super start];
}

- (void) stop
{
	[currentAction stop];
	[super stop];
}

- (void) update:(float) pComplete
{
	float pDelta = pComplete - pLastComplete;
	while(pCurrentActionComplete + pDelta >= pCurrentActionDuration)
	{
		if(currentAction.duration > 0)
		{
			[currentAction update:1.0];
		}
		[currentAction stop];
		pDelta -= (pCurrentActionDuration - pCurrentActionComplete);
		actionIndex++;
		if(actionIndex >= [actions count])
		{
			return;
		}
		currentAction = [actions objectAtIndex:actionIndex];
		pCurrentActionDuration = [[pDurations objectAtIndex:actionIndex] floatValue];
		pCurrentActionComplete = 0;
		[currentAction start];
	}
	
	if(pComplete >= 1.0)
	{
		// Make sure a cumulative rounding error doesn't cause an uncompletable action.
		[currentAction update:1.0];
		[currentAction stop];
	}
	else
	{
		pCurrentActionComplete += pDelta;
		[currentAction update:pCurrentActionComplete / pCurrentActionDuration];
	}
	
	pLastComplete = pComplete;
}

@end

#else /* !OBJECTAL_USE_COCOS2D_ACTIONS */

COCOS2D_SUBCLASS(OALSequentialActions);

#endif /* !OBJECTAL_USE_COCOS2D_ACTIONS */



#if !OBJECTAL_USE_COCOS2D_ACTIONS

#pragma mark -
#pragma mark OALConcurrentActions

@implementation OALConcurrentActions


#pragma mark Object Management

+ (id) actions:(OALAction*) firstAction, ...
{
	NSMutableArray* actions = [NSMutableArray arrayWithCapacity:10];
	va_list params;
	va_start(params, firstAction);
	OALAction* action = firstAction;
	
	while(nil != action)
	{
		[actions addObject:action];
		action = va_arg(params,OALAction*);
	}
	
	va_end(params);
	
	return [[[self alloc] initWithActions:actions] autorelease];
}

+ (id) actionsFromArray:(NSArray*) actions;
{
	return [[[self alloc] initWithActions:actions] autorelease];
}

- (id) initWithActions:(NSArray*) actionsIn
{
	if(nil != (self = [super initWithDuration:0]))
	{
		if([actionsIn isKindOfClass:[NSMutableArray class]])
		{
			actions = [actionsIn retain];
		}
		else
		{
			actions = [[NSMutableArray arrayWithArray:actionsIn] retain];
		}
		
		pDurations = [[NSMutableArray arrayWithCapacity:[actions count]] retain];
		actionsWithDuration = [[NSMutableArray arrayWithCapacity:[actions count]] retain];
	}
	return self;
}

- (void) dealloc
{
	[actions release];
	[pDurations release];
	[actionsWithDuration release];
	[super dealloc];
}


#pragma mark Properties

@synthesize actions;


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{
	[actionsWithDuration removeAllObjects];
	
	// Calculate the longest duration in seconds of all children.
	duration = 0;
	for(OALAction* action in actions)
	{
		[action prepareWithTarget:target];
		if(action.duration > 0)
		{
			if(action.duration > duration)
			{
				duration = action.duration;
			}
			
			// Also keep track of actions with durations.
			[actionsWithDuration addObject:action];
		}
	}
	
	// Calculate the childrens' durations as proportions of the total.
	[pDurations removeAllObjects];
	for(OALAction* action in actionsWithDuration)
	{
		[pDurations addObject:[NSNumber numberWithFloat:action.duration/duration]];
	}
	
	[super prepareWithTarget:targetIn];
}

- (void) start
{
	[actions makeObjectsPerformSelector:@selector(start)];
	[super start];
}

- (void) stop
{
	[actions makeObjectsPerformSelector:@selector(stop)];
	[super stop];
}

- (void) update:(float) proportionComplete
{
	if(0 == proportionComplete)
	{
		for(OALAction* action in actions)
		{
			[action update:0];
		}
	}
	else
	{
		for(int i = 0; i < [actionsWithDuration count]; i++)
		{
			OALAction* action = [actionsWithDuration objectAtIndex:i];
			float proportion = proportionComplete / [[pDurations objectAtIndex:i] floatValue];
			if(proportion > 1.0)
			{
				proportion = 1.0;
			}
			[action update:proportion];
		}
	}
}

@end

#else /* !OBJECTAL_USE_COCOS2D_ACTIONS */

COCOS2D_SUBCLASS(OALConcurrentActions);

#endif /* !OBJECTAL_USE_COCOS2D_ACTIONS */


#pragma mark -
#pragma mark OALCallAction

@implementation OALCallAction


#pragma mark Object Management

+ (id) actionWithCallTarget:(id) callTarget
				   selector:(SEL) selector
{
	return [[[self alloc] initWithCallTarget:callTarget selector:selector] autorelease];
}

+ (id) actionWithCallTarget:(id) callTarget
				   selector:(SEL) selector
				 withObject:(id) object
{
	return [[[self alloc] initWithCallTarget:callTarget
									selector:selector
								  withObject:object] autorelease];
}

+ (id) actionWithCallTarget:(id) callTarget
				   selector:(SEL) selector
				 withObject:(id) firstObject
				 withObject:(id) secondObject
{
	return [[[self alloc] initWithCallTarget:callTarget
									selector:selector
								  withObject:firstObject
								  withObject:secondObject] autorelease];
}

- (id) initWithCallTarget:(id) callTargetIn selector:(SEL) selectorIn
{
	if(nil != (self = [super init]))
	{
		callTarget = callTargetIn;
		selector = selectorIn;
	}
	return self;
}

- (id) initWithCallTarget:(id) callTargetIn
				 selector:(SEL) selectorIn
			   withObject:(id) object
{
	if(nil != (self = [super init]))
	{
		callTarget = callTargetIn;
		selector = selectorIn;
		object1 = object;
		numObjects = 1;
	}
	return self;
}

- (id) initWithCallTarget:(id) callTargetIn
				 selector:(SEL) selectorIn
			   withObject:(id) firstObject
			   withObject:(id) secondObject
{
	if(nil != (self = [super init]))
	{
		callTarget = callTargetIn;
		selector = selectorIn;
		object1 = firstObject;
		object2 = secondObject;
		numObjects = 2;
	}
	return self;
}


#pragma mark Functions

- (void) start
{
#if !OBJECTAL_USE_COCOS2D_ACTIONS
	[super start];
#endif /* !OBJECTAL_USE_COCOS2D_ACTIONS */
	
	switch(numObjects)
	{
		case 2:
			[callTarget performSelector:selector withObject:object1 withObject:object2];
			break;
		case 1:
			[callTarget performSelector:selector withObject:object1];
			break;
		default:
			[callTarget performSelector:selector];
	}
}

#if OBJECTAL_USE_COCOS2D_ACTIONS

-(void) startWithTarget:(id) targetIn
{
	[super startWithTarget:targetIn];
	[self start];
}

- (void) update:(float) proportionComplete
{
	// Nothing to do.
}

#endif /* OBJECTAL_USE_COCOS2D_ACTIONS */


@end
