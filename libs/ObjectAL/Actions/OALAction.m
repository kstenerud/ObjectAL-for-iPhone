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
@synthesize duration;
@synthesize elapsed;
@synthesize running;


#pragma mark Functions

- (void) runWithTarget:(id) targetIn
{
	[self prepareWithTarget:targetIn];
	[self startAction];
	[self updateCompletion:0];

	// Only add this action to the manager if it has a duration.
	if(duration > 0)
	{
		[[OALActionManager sharedInstance] notifyActionStarted:self];
		runningInManager = YES;
	}
	else
	{
		// If there's no duration, the action has completed.
		[self stopAction];
	}
}

- (void) prepareWithTarget:(id) targetIn
{
	NSAssert(!running, @"Error: Action is already running");

	target = targetIn;
}

- (void) startAction
{
	running = YES;
	elapsed = 0;
}

- (void) updateCompletion:(float) proportionComplete
{
	// Subclasses will override this.
}

- (void) stopAction
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

@implementation OALAction

- (id) init
{
	return [self initWithDuration:0];
}

-(void) startWithTarget:(id) targetIn
{
	[super startWithTarget:targetIn];
	[self prepareWithTarget:targetIn];
	started = YES;
	[self runWithTarget:targetIn];
}

- (void) update:(float) proportionComplete	
{
	// The only difference from COCOS2D_SUBCLASS() is that
	// I don't call [super update:] here.
	[self updateCompletion:proportionComplete];
}

- (bool) running
{
	return !self.isDone;
}

- (void) runWithTarget:(id) targetIn
{
	if(!started)
	{
		[[CCActionManager sharedManager] addAction:self target:targetIn paused:NO];
	}
}

- (void) stopAction
{
	[[CCActionManager sharedManager] removeAction:self];
}

- (void) prepareWithTarget:(id) targetIn
{
}

- (void) updateCompletion:(float) proportionComplete
{
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
		reverseFunction = [[OALReverseFunction alloc] initWithFunction:function];
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
	id <OALFunction,NSObject> oldValue = function;
	function = [value retain];
	[oldValue release];
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


