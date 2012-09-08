/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
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
 */


// Only compile this code on iOS. These files should NOT be included on your Mac project.
// But in case they are included, it won't be compiled.
#import "../../ccMacros.h"
#ifdef __CC_PLATFORM_IOS

#import "../../CCDirector.h"
#import "kazmath/mat4.h"

@class CCTouchDispatcher;

/** CCDirector extensions for iPhone
 */
@interface CCDirector (iOSExtension)

/** sets the CCTouchDispatcher (iOS only) */
@property (nonatomic,readwrite,retain) CCTouchDispatcher * touchDispatcher;

/** The size in pixels of the surface. It could be different than the screen size.
 High-res devices might have a higher surface size than the screen size.
 In non High-res device the contentScale will be emulated.

 The recommend way to enable Retina Display is by using the "enableRetinaDisplay:(BOOL)enabled" method.

 @since v0.99.4
 */
-(void) setContentScaleFactor:(CGFloat)scaleFactor;

/** Will enable Retina Display on devices that supports it.
 It will enable Retina Display on iPhone4 and iPod Touch 4.
 It will return YES, if it could enabled it, otherwise it will return NO.

 This is the recommened way to enable Retina Display.
 @since v0.99.5
 */
-(BOOL) enableRetinaDisplay:(BOOL)enableRetina;

/** returns the content scale factor */
-(CGFloat) contentScaleFactor;
@end

#pragma mark -
#pragma mark CCDirectorIOS

/** CCDirectorIOS: Base class of iOS directors
 @since v0.99.5
 */
@interface CCDirectorIOS : CCDirector
{
	/* contentScaleFactor could be simulated */
	BOOL	isContentScaleSupported_;
	
	CCTouchDispatcher	*touchDispatcher_;
}
@end

/** DisplayLinkDirector is a Director that synchronizes timers with the refresh rate of the display.
 *
 * Features and Limitations:
 * - Only available on 3.1+
 * - Scheduled timers & drawing are synchronizes with the refresh rate of the display
 * - Only supports animation intervals of 1/60 1/30 & 1/15
 *
 * It is the recommended Director if the SDK is 3.1 or newer
 *
 * @since v0.8.2
 */
@interface CCDirectorDisplayLink : CCDirectorIOS
{
	CADisplayLink	*displayLink_;
	CFTimeInterval	lastDisplayTime_;
}
-(void) mainLoop:(id)sender;
@end

// optimization. Should only be used to read it. Never to write it.
extern CGFloat	__ccContentScaleFactor;

#endif // __CC_PLATFORM_IOS
