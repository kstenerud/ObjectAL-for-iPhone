//
//  OALFunction.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-22.
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

#import "OALFunction.h"
#import "ObjectALMacros.h"


#pragma mark OALLinearFunction

SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(OALLinearFunction);

@implementation OALLinearFunction


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALLinearFunction);

+ (id) function
{
	return [self sharedInstance];
}


#pragma mark Function

- (float) valueForInput:(float) inputValue
{
	return inputValue;
}

@end



#pragma mark -
#pragma mark OALSCurveFunction

SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(OALSCurveFunction);

@implementation OALSCurveFunction


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALSCurveFunction);

+ (id) function
{
	return [self sharedInstance];
}


#pragma mark Function

- (float) valueForInput:(float) inputValue
{
	// x^2 * (3-2x)
	return inputValue * inputValue * (3.0f - 2.0f * inputValue);
}

@end



#pragma mark -
#pragma mark OALExponentialFunction

SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(OALExponentialFunction);

@implementation OALExponentialFunction


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALExponentialFunction);

+ (id) function
{
	return [self sharedInstance];
}


#pragma mark Function

- (float) valueForInput:(float) inputValue
{
	// (10^(x-1) - 10^-1) * (1 / (1 - 10^-1))
	return (powf(10.f,inputValue-1.0f) - 0.1f) * (1.0f/0.9f);
}

@end



#pragma mark -
#pragma mark OALLogarithmicFunction

SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(OALLogarithmicFunction);

@implementation OALLogarithmicFunction


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALLogarithmicFunction);

+ (id) function
{
	return [self sharedInstance];
}


#pragma mark Function

- (float) valueForInput:(float) inputValue
{
	// log10(x * (1 - 10^-1) + 10^-1) + 1
	return log10f(inputValue * 0.9f + 0.1f) + 1.0f;
}

@end



#pragma mark -
#pragma mark OALReverseFunction

@implementation OALReverseFunction


#pragma mark Object Management

+ (id) functionWithFunction:(id<OALFunction, NSObject>) function
{
	return arcsafe_autorelease([[self alloc] initWithFunction:function]);
}

- (id) initWithFunction:(id<OALFunction, NSObject>) functionIn
{
	if(nil != (self = [super init]))
	{
		function = arcsafe_retain(functionIn);
	}
	return self;
}

- (void) dealloc
{
	arcsafe_release(function);
    arcsafe_super_dealloc();
}


#pragma mark Properties

// Compiler bug?
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-atomic-properties"
@synthesize function;
#pragma clang diagnostic pop


#pragma mark Function

- (float) valueForInput:(float) inputValue
{
	return [function valueForInput:1.0f - inputValue];
}

@end
