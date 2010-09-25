//
//  MainLayer.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//


#import "cocos2d.h"
#import "ImageButton.h"

/**
 * Main layer to the ObjectAL demo program.
 * Contains a menu which redirects to various scenes. <br>
 *
 * Be sure to look at the header files for the various demos as they give important information.
 */
@interface MainLayer : CCLayer
{
	NSMutableArray* sceneNames;
	NSMutableArray* scenes;
	ImageButton* previousButton;
	ImageButton* nextButton;
	
	CCMenu* menu;
	CCMenu* oldMenu;
}

@end
