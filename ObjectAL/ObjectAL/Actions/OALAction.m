//
//  OALAction.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-18.
//
//  Copyright (c) 2009 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// Attribution is not required, but appreciated :)
//

#import "OALAction.h"
#import "OALActionManager.h"
#import "ObjectALMacros.h"


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
    #pragma unused(proportionComplete)
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
	return arcsafe_autorelease([[self alloc] initWithDuration:duration
                                                     endValue:endValue]);
}

+ (id) actionWithDuration:(float) duration
				 endValue:(float) endValue
				 function:(id<OALFunction,NSObject>) function
{
	return arcsafe_autorelease([[self alloc] initWithDuration:duration
                                                     endValue:endValue
                                                     function:function]);
}

+ (id) actionWithDuration:(float) duration
			   startValue:(float) startValue
				 endValue:(float) endValue
				 function:(id<OALFunction,NSObject>) function
{
	return arcsafe_autorelease([[self alloc] initWithDuration:duration
                                                   startValue:startValue
                                                     endValue:endValue
                                                     function:function]);
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
		function = arcsafe_retain(functionIn);
		reverseFunction = [[OALReverseFunction alloc] initWithFunction:function];
		realFunction = function;
	}
	return self;
}

- (void) dealloc
{
	arcsafe_release(function);
	arcsafe_release(reverseFunction);
    arcsafe_super_dealloc();
}


#pragma mark Properties

- (id<OALFunction,NSObject>) function
{
	return function;
}

- (void) setFunction:(id <OALFunction,NSObject>) value
{
    arcsafe_autorelease_unused(function);
	function = arcsafe_retain(value);
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


