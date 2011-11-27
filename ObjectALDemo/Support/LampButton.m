//
//  LampButton.m
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "LampButton.h"
#import "CCNode+ContentSize.h"


@implementation LampButton

+ (id) buttonWithText:(NSString*) text
				 font:(NSString*) font
				 size:(float) fontSize
		   lampOnLeft:(bool) lampOnLeft
			   target:(id) target
			 selector:(SEL) selector
{
	return [[[self alloc] initWithText:text
								  font:font
								  size:fontSize
							lampOnLeft:lampOnLeft
								target:target
							  selector:selector] autorelease];
}

- (id) initWithText:(NSString*) text
			   font:(NSString*) font
			   size:(float) fontSize
		 lampOnLeft:(bool) lampOnLeft
			 target:(id) targetIn
		   selector:(SEL) selectorIn
{
	label = [CCLabelTTF labelWithString:text fontName:font fontSize:fontSize];
	label.anchorPoint = ccp(0.5f, 0.5f);

	lampOn = [CCSprite spriteWithFile:@"panel-lamp-on.png"];
	lampOn.anchorPoint = ccp(0.5f, 0.5f);
	lampOff = [CCSprite spriteWithFile:@"panel-lamp-off.png"];
	lampOff.anchorPoint = ccp(0.5f, 0.5f);
	
	float maxHeight = lampOn.contentSize.height;
	if(lampOff.contentSize.height > maxHeight)
	{
		maxHeight = lampOff.contentSize.height;
	}
	if(label.contentSize.height > maxHeight)
	{
		maxHeight = label.contentSize.height;
	}
	
	float halfHeight = maxHeight * 0.5f;

	if(lampOnLeft)
	{
		label.position = ccp(lampOn.contentSize.width + 4 + label.contentSize.width*0.5f, halfHeight);
		lampOn.position = lampOff.position = ccp(lampOn.contentSize.width*0.5f, halfHeight);
	}
	else
	{
		label.position = ccp(label.contentSize.width*0.5f, halfHeight);
		lampOn.position = lampOff.position = ccp(label.contentSize.width + 4 + lampOn.contentSize.width*0.5f, halfHeight);
	}
	
	lampOn.visible = NO;

	CCNode* node = [CCNode node];
	[node addChild:lampOn];
	[node addChild:lampOff];
	[node addChild:label];
	[node setContentSizeFromChildren];
	
	if(nil != (self = [super initWithTouchablePortion:node target:targetIn selector:selectorIn]))
	{
		scaleOnPush = NO;
	}
	return self;
}

- (void) onButtonPressed
{
	self.isOn = !self.isOn;
	[super onButtonPressed];
}

@synthesize label;

- (bool) isOn
{
	return lampOn.visible;
}

- (void) setIsOn:(bool) value
{
	lampOn.visible = value;
	lampOff.visible = !value;
}

@end
