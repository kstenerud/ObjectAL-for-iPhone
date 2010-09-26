//
//  OALFunction.h
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
 * <b>- (BackgroundAudio*) sharedInstance</b>: Get the shared singleton instance. <br>
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
 * <b>- (BackgroundAudio*) sharedInstance</b>: Get the shared singleton instance. <br>
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
 * <b>- (BackgroundAudio*) sharedInstance</b>: Get the shared singleton instance. <br>
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
 * <b>- (BackgroundAudio*) sharedInstance</b>: Get the shared singleton instance. <br>
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
