//
//  OALFunction.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-22.
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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALFunction.h"


#pragma mark OALLinearFunction

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
	return inputValue * inputValue * (3.0 - 2.0 * inputValue);
}

@end



#pragma mark -
#pragma mark OALExponentialFunction

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
	return (powf(10,inputValue-1.0) - 0.1) * (1.0/0.9);
}

@end



#pragma mark -
#pragma mark OALLogarithmicFunction

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
	return log10f(inputValue * 0.9 + 0.1) + 1.0;
}

@end



#pragma mark -
#pragma mark OALReverseFunction

@implementation OALReverseFunction


#pragma mark Object Management

+ (id) functionWithFunction:(id<OALFunction, NSObject>) function
{
	return [[[self alloc] initWithFunction:function] autorelease];
}

- (id) initWithFunction:(id<OALFunction, NSObject>) functionIn
{
	if(nil != (self = [super init]))
	{
		function = [functionIn retain];
	}
	return self;
}

- (void) dealloc
{
	[function release];
	[super dealloc];
}


#pragma mark Properties

@synthesize function;


#pragma mark Function

- (float) valueForInput:(float) inputValue
{
	return [function valueForInput:1.0 - inputValue];
}

@end
