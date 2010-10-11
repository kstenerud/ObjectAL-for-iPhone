//
//  OALAction.m
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

#import "OALAction.h"
#import "OALActionManager.h"
#import "mach_timing.h"


#if OBJECTAL_USE_COCOS2D_ACTIONS

#define COCOS2D_SUBCLASS(CLASS_A)	\
@implementation CLASS_A	\
	\
- (id) init	\
{	\
	return [self initWithDuration:0];	\
}	\
	\
- (bool) running	\
{	\
	return started && !self.isDone;	\
}	\
- (void) runWithTarget:(id) targetIn	\
{	\
	if(!started)	\
	{	\
		[[CCActionManager sharedManager] addAction:self target:targetIn paused:NO];	\
	}	\
}	\
	\
- (void) prepareWithTarget:(id) targetIn	\
{	\
}	\
	\
-(void) startWithTarget:(id) targetIn	\
{	\
	[super startWithTarget:targetIn];	\
	[self prepareWithTarget:targetIn];	\
	started = YES;	\
	[self runWithTarget:targetIn];	\
}	\
	\
@end

#endif /* OBJECTAL_USE_COCOS2D_ACTIONS */



#if !OBJECTAL_USE_COCOS2D_ACTIONS


#pragma mark OALAction (ObjectAL version)

@implementation OALAction


#pragma mark Object Management

- (id) init
{
	return [self initWithDuration:0];
}

- (id) initWithDuration:(float) durationIn
{
	if(nil != (self = [super init]))
	{
		duration = durationIn;
	}
	return self;
}


#pragma mark Properties

@synthesize target;
@synthesize startTime;
@synthesize duration;
@synthesize running;


#pragma mark Functions

- (void) runWithTarget:(id) targetIn
{
	[self prepareWithTarget:targetIn];
	[self start];
	[self update:0];

	if(duration > 0)
	{
		[[OALActionManager sharedInstance] notifyActionStarted:self];
		runningInManager = YES;
	}
	else
	{
		[self stop];
	}
}

- (void) prepareWithTarget:(id) targetIn
{
	NSAssert(!running, @"Error: Action is already running");

	target = targetIn;
}

- (void) start
{
	running = YES;
	startTime = mach_absolute_time();
}

- (void) update:(float) proportionComplete
{
	// Subclasses will override this.
}

- (void) stop
{
	running = NO;
	if(runningInManager)
	{
		[[OALActionManager sharedInstance] notifyActionStopped:self];
		runningInManager = NO;
	}
}

@end


#else /* !OBJECTAL_USE_COCOS2D_ACTIONS */

COCOS2D_SUBCLASS(OALAction);

#endif /* !OBJECTAL_USE_COCOS2D_ACTIONS */


#pragma mark -
#pragma mark OALFunctionAction

@implementation OALFunctionAction


#pragma mark Object Management

+ (id) actionWithDuration:(float) duration
				 endValue:(float) endValue
{
	return [[[self alloc] initWithDuration:duration
								  endValue:endValue] autorelease];
}

+ (id) actionWithDuration:(float) duration
				 endValue:(float) endValue
				 function:(id<OALFunction,NSObject>) function
{
	return [[[self alloc] initWithDuration:duration
								  endValue:endValue
								  function:function] autorelease];
}

+ (id) actionWithDuration:(float) duration
			   startValue:(float) startValue
				 endValue:(float) endValue
				 function:(id<OALFunction,NSObject>) function
{
	return [[[self alloc] initWithDuration:duration
								startValue:startValue
								  endValue:endValue
								  function:function] autorelease];
}

- (id) initWithDuration:(float) durationIn endValue:(float) endValueIn
{
	return [self initWithDuration:durationIn
					   startValue:NAN
						 endValue:endValueIn
						 function:[[self class] defaultFunction]];
}

- (id) initWithDuration:(float) durationIn
			   endValue:(float) endValueIn
			   function:(id<OALFunction,NSObject>) functionIn
{
	return [self initWithDuration:durationIn
					   startValue:NAN
						 endValue:endValueIn
						 function:functionIn];
}

- (id) initWithDuration:(float) durationIn
			 startValue:(float) startValueIn
			   endValue:(float) endValueIn
			   function:(id<OALFunction,NSObject>) functionIn
{
	if(nil != (self = [super initWithDuration:durationIn]))
	{
		startValue = startValueIn;
		endValue = endValueIn;
		function = [functionIn retain];
		reverseFunction = [[OALReverseFunction functionWithFunction:function] retain];
		realFunction = function;
	}
	return self;
}

- (void) dealloc
{
	[function release];
	[reverseFunction release];
	[super dealloc];
}


#pragma mark Properties

- (id<OALFunction,NSObject>) function
{
	return function;
}

- (void) setFunction:(id <OALFunction,NSObject>) value
{
	[function autorelease];
	function = [value retain];
	reverseFunction.function = function;
}

@synthesize startValue;

@synthesize endValue;


#pragma mark Utility

+ (id<OALFunction,NSObject>) defaultFunction
{
	return [OALLinearFunction function];
}


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{
	[super prepareWithTarget:targetIn];

	delta = endValue - startValue;
	
	if(delta < 0)
	{
		// If delta is negative, we need the reversed function.
		realFunction = reverseFunction;
		lowValue = endValue;
		delta = -delta;
	}
	else
	{
		realFunction = function;
		lowValue = startValue;
	}
}

@end


#pragma mark -
#pragma mark OALAction_GainProtocol

/** Protocol to stop the compiler from complaining */
@protocol OALAction_GainProtocol

/** The gain (volume), represented as a float from 0.0 to 1.0. */
@property(readwrite) float gain;

@end


#pragma mark -
#pragma mark OALGainAction

@implementation OALGainAction


#pragma mark Utility

+ (id<OALFunction,NSObject>) defaultFunction
{
	return [OALSCurveFunction function];
}


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(gain)]
			 && [targetIn respondsToSelector:@selector(setGain:)],
			 @"Target does not respond to selectors [gain] and [setGain:]");
	
	if(isnan(startValue))
	{
		startValue = [(id<OALAction_GainProtocol>)targetIn gain];
	}

	[super prepareWithTarget:targetIn];
}

- (void) update:(float) proportionComplete
{
	[(id<OALAction_GainProtocol>)target setGain:lowValue
	 + [realFunction valueForInput:proportionComplete] * delta];
}

@end


#pragma mark -
#pragma mark OALAction_PitchProtocol

/** Protocol to stop the compiler from complaining */
@protocol OALAction_PitchProtocol

/** The pitch, represented as a float with 1.0 representing normal pitch. */
@property(readwrite) float pitch;

@end


#pragma mark -
#pragma mark OALPitchAction

@implementation OALPitchAction


#pragma mark Utility

+ (id<OALFunction,NSObject>) defaultFunction
{
	return [OALLinearFunction function];
}


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{	
	NSAssert([targetIn respondsToSelector:@selector(pitch)]
			 && [targetIn respondsToSelector:@selector(setPitch:)],
			 @"Target does not respond to selectors [pitch] and [setPitch:]");
	
	if(isnan(startValue))
	{
		startValue = [(id<OALAction_PitchProtocol>)targetIn pitch];
	}

	[super prepareWithTarget:targetIn];
}

- (void) update:(float) proportionComplete
{
	[(id<OALAction_PitchProtocol>)target setPitch:startValue
	 + [realFunction valueForInput:proportionComplete] * delta];
}

@end


#pragma mark -
#pragma mark OALAction_PanProtocol

/** Protocol to stop the compiler from complaining */
@protocol OALAction_PanProtocol

/** The pan, represented as a float from -1.0 to 1.0. */
@property(readwrite) float pan;

@end


#pragma mark -
#pragma mark OALPanAction

@implementation OALPanAction


#pragma mark Utility

+ (id<OALFunction,NSObject>) defaultFunction
{
	return [OALLinearFunction function];
}


#pragma mark Functions

- (void) prepareWithTarget:(id) targetIn
{	
	NSAssert([targetIn respondsToSelector:@selector(pan)]
			 && [targetIn respondsToSelector:@selector(setPan:)],
			 @"Target does not respond to selectors [pan] and [setPan:]");
	
	if(isnan(startValue))
	{
		startValue = [(id<OALAction_PanProtocol>)targetIn pan];
	}

	[super prepareWithTarget:targetIn];
}

- (void) update:(float) proportionComplete
{
	[(id<OALAction_PanProtocol>)target setPan:startValue
	 + [realFunction valueForInput:proportionComplete] * delta];
}

@end


@protocol OALAction_PositionProtocol

@property(readwrite,assign) ALPoint position;

@end


@implementation OALPlaceAction

+ (id) actionWithPosition:(ALPoint) position
{
	return [[[self alloc] initWithPosition:position] autorelease];
}

- (id) initWithPosition:(ALPoint) positionIn
{
	if(nil != (self = [super init]))
	{
		position = positionIn;
	}
	return self;
}

@synthesize position;

- (void) prepareWithTarget:(id) targetIn
{	
	NSAssert([targetIn respondsToSelector:@selector(setPosition:)],
			 @"Target does not respond to selector [setPosition:]");
	
	[super prepareWithTarget:targetIn];
}

- (void) start
{
	[super start];
	[(id<OALAction_PositionProtocol>)target setPosition:position];
}

@end



@implementation OALMoveToAction

+ (id) actionWithDuration:(float) duration position:(ALPoint) position
{
	return [[[self alloc] initWithDuration:duration position:position] autorelease];
}

+ (id) actionWithUnitsPerSecond:(float) unitsPerSecond position:(ALPoint) position
{
	return [[[self alloc] initWithUnitsPerSecond:unitsPerSecond position:position] autorelease];
}

- (id) initWithDuration:(float) durationIn position:(ALPoint) positionIn
{
	if(nil != (self = [super initWithDuration:durationIn]))
	{
		position = positionIn;
	}
	return self;
}

- (id) initWithUnitsPerSecond:(float) unitsPerSecondIn position:(ALPoint) positionIn
{
	if(nil != (self = [super init]))
	{
		position = positionIn;
		unitsPerSecond = unitsPerSecondIn;
	}
	return self;
}

@synthesize position;
@synthesize unitsPerSecond;

- (void) prepareWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(setPosition:)],
			 @"Target does not respond to selector [setPosition:]");

	[super prepareWithTarget:targetIn];
	startPoint = [(id<OALAction_PositionProtocol>)targetIn position];
	delta = ALPointMake(position.x-startPoint.x, position.y-startPoint.y, position.z - startPoint.z);
	if(unitsPerSecond > 0)
	{
		duration = sqrtf(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z) / unitsPerSecond;
	}
}

- (void) update:(float) proportionComplete
{
	[(id<OALAction_PositionProtocol>)target setPosition:
	 ALPointMake(startPoint.x + delta.x*proportionComplete,
				 startPoint.y + delta.y*proportionComplete,
				 startPoint.z + delta.z*proportionComplete)];
}

@end


@implementation OALMoveByAction

+ (id) actionWithDuration:(float) duration delta:(ALPoint) delta
{
	return [[[self alloc] initWithDuration:duration delta:delta] autorelease];
}

+ (id) actionWithUnitsPerSecond:(float) unitsPerSecond delta:(ALPoint) delta
{
	return [[[self alloc] initWithUnitsPerSecond:unitsPerSecond delta:delta] autorelease];
}

- (id) initWithDuration:(float) durationIn delta:(ALPoint) deltaIn
{
	if(nil != (self = [super initWithDuration:durationIn]))
	{
		delta = deltaIn;
	}
	return self;
}

- (id) initWithUnitsPerSecond:(float) unitsPerSecondIn delta:(ALPoint) deltaIn
{
	if(nil != (self = [super init]))
	{
		delta = deltaIn;
		unitsPerSecond = unitsPerSecondIn;
	}
	return self;
}

@synthesize delta;
@synthesize unitsPerSecond;

- (void) prepareWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(setPosition:)],
			 @"Target does not respond to selector [setPosition:]");
	
	[super prepareWithTarget:targetIn];
	startPoint = [(id<OALAction_PositionProtocol>)targetIn position];
	if(unitsPerSecond > 0)
	{
		duration = sqrtf(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z) / unitsPerSecond;
	}
}

- (void) update:(float) proportionComplete
{
	[(id<OALAction_PositionProtocol>)target setPosition:
	 ALPointMake(startPoint.x + delta.x*proportionComplete,
				 startPoint.y + delta.y*proportionComplete,
				 startPoint.z + delta.z*proportionComplete)];
}

@end


@implementation OALTargetedAction

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

@implementation OALSequentialActions

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

@synthesize actions;

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

@implementation OALConcurrentActions

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

@synthesize actions;

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


@implementation OALCall

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
