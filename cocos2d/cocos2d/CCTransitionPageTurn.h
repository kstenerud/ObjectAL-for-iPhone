/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2009 Sindesso Pty Ltd http://www.sindesso.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */


#import "CCTransition.h"

/** CCTransitionPageTurn transition.
 * A transition which peels back the bottom right hand corner of a scene
 * to transition to the scene beneath it simulating a page turn
 *
 * This uses a 3DAction so it is strongly recommended that depth buffering
 * is turned on in CCDirector using:
 *
 * 	[[CCDirector sharedDirector] setDepthBufferFormat:kCCDepthBuffer16];
 *
 * @since v0.8.2
 */
@interface CCTransitionPageTurn : CCTransitionScene
{
	BOOL	back_;
}
/**
 * creates a base transition with duration and incoming scene
 * if back is TRUE then the effect is reversed to appear as if the incoming
 * scene is being turned from left over the outgoing scene
 */
+(id) transitionWithDuration:(ccTime) t scene:(CCScene*)s backwards:(BOOL) back;

/**
 * creates a base transition with duration and incoming scene
 * if back is TRUE then the effect is reversed to appear as if the incoming
 * scene is being turned from left over the outgoing scene
 */
-(id) initWithDuration:(ccTime) t scene:(CCScene*)s backwards:(BOOL) back;

-(CCActionInterval*) actionWithSize:(ccGridSize) vector;

@end
