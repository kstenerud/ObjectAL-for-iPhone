//
//  OALActionManager.h
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

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "OALAction.h"
#import "ObjectALConfig.h"

/* This object is only available if OBJECTAL_USE_COCOS2D_ACTIONS is enabled in ObjectALConfig.h.
 */
#if !OBJECTAL_USE_COCOS2D_ACTIONS


#pragma mark OALActionManager

/**
 * Manages all ObjectAL actions.
 */
@interface OALActionManager : NSObject
{
	/** All targets that have actions running on them (id). */
	NSMutableArray* targets;
	
	/** Parallel array to "targets", maintaining a list of all actions per target (NSMutableArray*) */
	NSMutableArray* targetActions;
	
	/** All actions that are to be added on the next pass (OALAction*) */
	NSMutableArray* actionsToAdd;
	
	/** All actions that are to be removed on the next pass (OALAction*) */
	NSMutableArray* actionsToRemove;
	
	/** The timer which we use to update the actions. */
	NSTimer* stepTimer;
}


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (IphoneAudioSupport*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OALActionManager);


#pragma mark Action Management

/** Stops ALL running actions on ALL targets.
 */
- (void) stopAllActions;


#pragma mark Internal Use

/** (INTERNAL USE)  Used by OALAction to announce that it is starting.
 *
 * @param action The action that is starting.
 */
- (void) notifyActionStarted:(OALAction*) action;

/** (INTERNAL USE)  Used by OALAction to announce that it is stopping.
 *
 * @param action The action that is stopping.
 */
- (void) notifyActionStopped:(OALAction*) action;

@end

#endif /* OBJECTAL_USE_COCOS2D_ACTIONS */
