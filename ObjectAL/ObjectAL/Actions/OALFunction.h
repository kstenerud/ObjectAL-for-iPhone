//
//  OALFunction.h
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

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"


#pragma mark OALFunction

/**
 * A function takes a value from 0.0 to 1.0 and returns
 * another value from 0.0 to 1.0.
 */
@protocol OALFunction


#pragma mark Function

/** Calculate the function value.
 *
 * @param inputValue A value from 0.0 to 1.0
 * @return The resulting value, which will also be from 0.0 to 1.0.
 */
- (float) valueForInput:(float) inputValue;

@end



#pragma mark -
#pragma mark OALLinearFunction

/** Function that changes at a constant rate.
 * <pre>
                       ##
                     ##
                   ##
                 ##
               ##
             ##
           ##
         ##
       ##
     ##
   ##
 </pre>
 */
@interface OALLinearFunction : NSObject <OALFunction>
{
}


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (OALLinearFunction*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OALLinearFunction);

/** Generate an instance of this function.
 *
 * @return An instance of this function.
 */
+ (id) function;

@end



#pragma mark -
#pragma mark OALSCurveFunction

/** Changes slowly at the start, quickly at the midpoint, then slowly
 * again at the end.
 * <pre>
                    ####
                 ###
               ##
              #
             #
             #
             #
            #
          ##
       ###
   ####
 </pre>
 */
@interface OALSCurveFunction : NSObject <OALFunction>
{
}


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (OALSCurveFunction*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OALSCurveFunction);

/** Generate an instance of this function.
 *
 * @return An instance of this function.
 */
+ (id) function;

@end



#pragma mark -
#pragma mark OALExponentialFunction

/** Changes slowly at the start, and quickly at the end.
 * <pre>
                         #
                         #
                         #
                        #
                        #
                       #
                     ##
                  ###
              ####
         #####
   ######
 </pre>
 */
@interface OALExponentialFunction : NSObject <OALFunction>
{
}


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (OALExponentialFunction*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OALExponentialFunction);

/** Generate an instance of this function.
 *
 * @return An instance of this function.
 */
+ (id) function;

@end



#pragma mark -
#pragma mark OALLogarithmicFunction

/** Changes quickly at the start, and slowly at the end.
 * <pre>
                    ######
               #####
           ####
        ###
      ##
     #
    #
    #
   #
   #
   #
 </pre>
 */
@interface OALLogarithmicFunction : NSObject <OALFunction>
{
}


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (OALLogarithmicFunction*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OALLogarithmicFunction);

/** Generate an instance of this function.
 *
 * @return An instance of this function.
 */
+ (id) function;

@end



#pragma mark -
#pragma mark OALReverseFunction

/** Returns the reverse of another function.
 * For example, a linear up ramp will become a linear down ramp:
 * <pre>
   | Before:      | After:       |
   |           ## | ##           |
   |         ##   |   ##         |
   |       ##     |     ##       |
   |     ##       |       ##     |
   |   ##         |         ##   |
   | ##           |           ## |
 </pre>
 */
@interface OALReverseFunction : NSObject <OALFunction>
{
	id<OALFunction, NSObject> function;
}


#pragma mark Properties

/** The function which will have its value reversed. */
@property(readwrite,retain) id<OALFunction, NSObject> function;


#pragma mark Object Management

/** Create a new reverse function.
 *
 * @param function The function to reverse.
 * @return the new reversed function.
 */
+ (id) functionWithFunction:(id<OALFunction, NSObject>) function;

/** Initialize a reverse function.
 *
 * @param function The function to reverse.
 * @return the initialized reversed function.
 */
- (id) initWithFunction:(id<OALFunction, NSObject>) function;


@end
