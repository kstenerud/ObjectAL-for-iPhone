//
//  FadeDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-17.
//

#import "cocos2d.h"
#import <ObjectAL/ObjectAL.h>
#import "LampButton.h"

@interface FadeDemo : CCLayerColor
{
	id<ALSoundSource> source;

	LampButton* startStopSourceButton;
	LampButton* fadeOutSourceButton;
	LampButton* fadeInSourceButton;
	
	LampButton* startStopTrackButton;
	LampButton* fadeOutTrackButton;
	LampButton* fadeInTrackButton;
}

@end
