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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALAction.h"
#import "OALActionManager.h"
#import "mach_timing.h"


#if !OBJECTAL_USE_COCOS2D_ACTIONS


#pragma mark OALAction (ObjectAL version)

@implementation OALAction


#pragma mark Object Management

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
	NSAssert(!running, @"Error: Action is already running");

	target = targetIn;
	running = YES;
	startTime = mach_absolute_time();
	[self update:0];
	if(duration > 0)
	{
		[[OALActionManager sharedInstance] notifyActionStarted:self];
	}
	else
	{
		running = NO;
	}

}

- (void) update:(float) proportionComplete
{
	// Subclasses will override this.
}

- (void) stop
{
	if(running)
	{
		running = NO;
		[[OALActionManager sharedInstance] notifyActionStopped:self];
	}
}

@end


#else /* !OBJECTAL_USE_COCOS2D_ACTIONS */


#pragma mark -
#pragma mark OALAction (Cocos2d version)

@implementation OALAction


#pragma mark Properties

- (bool) running
{
	return !self.isDone;
}


#pragma mark Functions

- (void) runWithTarget:(id) targetIn
{
	if(!started)
	{
		[[CCActionManager sharedManager] addAction:self target:targetIn paused:NO];
	}
}

-(void) startWithTarget:(id) targetIn
{
	[super startWithTarget:targetIn];
	started = YES;
	[self runWithTarget:targetIn];
}

@end


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

- (void) runWithTarget:(id) targetIn
{
	target = targetIn;

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

	[super runWithTarget:targetIn];
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

- (void) runWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(gain)]
			 && [targetIn respondsToSelector:@selector(setGain:)],
			 @"Target does not respond to selectors [gain] and [setGain:]");
	
	if(isnan(startValue))
	{
		startValue = [(id<OALAction_GainProtocol>)targetIn gain];
	}
	
	[super runWithTarget:targetIn];
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

- (void) runWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(pitch)]
			 && [targetIn respondsToSelector:@selector(setPitch:)],
			 @"Target does not respond to selectors [pitch] and [setPitch:]");
	
	if(isnan(startValue))
	{
		startValue = [(id<OALAction_PitchProtocol>)targetIn pitch];
	}
	
	[super runWithTarget:targetIn];
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

- (void) runWithTarget:(id) targetIn
{
	NSAssert([targetIn respondsToSelector:@selector(pan)]
			 && [targetIn respondsToSelector:@selector(setPan:)],
			 @"Target does not respond to selectors [pan] and [setPan:]");
	
	if(isnan(startValue))
	{
		startValue = [(id<OALAction_PanProtocol>)targetIn pan];
	}
	
	[super runWithTarget:targetIn];
}

- (void) update:(float) proportionComplete
{
	[(id<OALAction_PanProtocol>)target setPan:startValue
	 + [realFunction valueForInput:proportionComplete] * delta];
}

@end
