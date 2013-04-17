//
//  AppDelegate.h
//  ObjectALDemo
//
//  Created by Karl Stenerud on 4/15/13.
//  Copyright Karl Stenerud 2013. All rights reserved.
//

#import "cocos2d.h"

@interface ObjectALDemoAppDelegate : NSObject <NSApplicationDelegate>
{
	NSWindow	*window_;
	CCGLView	*glView_;
}

@property (assign) IBOutlet NSWindow	*window;
@property (assign) IBOutlet CCGLView	*glView;

- (IBAction)toggleFullScreen:(id)sender;

@end
