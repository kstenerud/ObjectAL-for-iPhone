//
//  ObjectALAppDelegate.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "ObjectALAppDelegate.h"
#import "cocos2d.h"
#import "CCLayer+Scene.h"
#import "MainScene.h"
#import "ObjectAL.h"

@implementation ObjectALAppDelegate

@synthesize window;

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	// CC_DIRECTOR_INIT()
	//
	// 1. Initializes an EAGLView with 0-bit depth format, and RGB565 render buffer
	// 2. EAGLView multiple touches: disabled
	// 3. creates a UIWindow, and assign it to the "window" var (it must already be declared)
	// 4. Parents EAGLView to the newly created window
	// 5. Creates Display Link Director
	// 5a. If it fails, it will use an NSTimer director
	// 6. It will try to run at 60 FPS
	// 7. Display FPS: NO
	// 8. Device orientation: Portrait
	// 9. Connects the director to the EAGLView
	//
	CC_DIRECTOR_INIT();
	
	// Obtain the shared director in order to...
	CCDirector *director = [CCDirector sharedDirector];
	
	// Sets landscape mode
	[director setDeviceOrientation:kCCDeviceOrientationLandscapeLeft];
	
	// Turn on display FPS
	[director setDisplayFPS:NO];
	
	// Turn on multiple touches
	EAGLView *view = [director openGLView];
	[view setMultipleTouchEnabled:YES];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_RGBA8888];	
	
	// I'm creating the OALSimpleAudio singleton here as a shortcut to initialize
	// the underlying audio libraries, which can take some time to start up.
	[OALSimpleAudio sharedInstance];

	// I destroy it here as well because OALSimpleAudio takes all of ObjectAL's
	// sources by default, and some of the demos would fail when they tried to use
	// ObjectAL directly.
	[OALSimpleAudio purgeSharedInstance];

	// We want interruptions handled automatically so we don't have to worry about them.
	[OALAudioSupport sharedInstance].handleInterruptions = YES;

	[[CCDirector sharedDirector] runWithScene: [MainLayer scene]];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[[CCDirector sharedDirector] resume];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[[CCDirector sharedDirector] stopAnimation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[[CCDirector sharedDirector] end];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void)dealloc {
	[[CCDirector sharedDirector] release];
	[window release];
	[super dealloc];
}

@end
