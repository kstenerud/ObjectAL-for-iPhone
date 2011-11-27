//
//  Slider.m
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "Slider.h"


#pragma mark Slider

@implementation Slider

#pragma mark Object Management

+ (id) sliderWithTrack:(CCNode*) track
				  knob:(CCNode*) knob
			   padding:(CGSize) padding
				target:(id) target
		  moveSelector:(SEL) moveSelector
		  dropSelector:(SEL) dropSelector
{
	return [[[self alloc] initWithTrack:track
								   knob:knob
								padding:padding
								 target:target
						   moveSelector:moveSelector
						   dropSelector:dropSelector] autorelease];
}

- (id) initWithTrack:(CCNode*) trackIn
				knob:(CCNode*) knobIn
			 padding:(CGSize) padding
			  target:(id) targetIn
		moveSelector:(SEL) moveSelectorIn
		dropSelector:(SEL) dropSelectorIn
{
	if(nil != (self = [super init]))
	{
		target = targetIn;
		moveSelector = moveSelectorIn;
		dropSelector = dropSelectorIn;
		
		track = trackIn;
		[self addChild:track z:10];
		
		knob = knobIn;
		[self addChild:knob z:20];

		scaleUpAction = [[CCScaleBy actionWithDuration:0.1f scale:1.2f] retain];
		scaleDownAction = [[CCSequence actionOne:[CCScaleBy actionWithDuration:0.02f scale:1.1f]
											 two:[CCScaleTo actionWithDuration:0.05f scaleX:knob.scaleX scaleY:knob.scaleY]] retain];

		CGSize knobSize = CGSizeMake(knob.contentSize.width * knob.scaleX, knob.contentSize.height * knob.scaleY);
		CGSize trackSize = CGSizeMake(track.contentSize.width * track.scaleX, track.contentSize.height * track.scaleY);
		CGSize combinedSize = CGSizeMake(knobSize.width > trackSize.width ? knobSize.width : trackSize.width,
										 knobSize.height > trackSize.height ? knobSize.height : trackSize.height);
		combinedSize.width += padding.width*2;
		combinedSize.height += padding.height*2;
		
		self.contentSize = combinedSize;
		touchPriority = 0;
		targetedTouches = YES;
		swallowTouches = YES;
		isTouchEnabled = YES;
		self.isRelativeAnchorPoint = YES;
		self.anchorPoint = ccp(0.5f, 0.5f);		
	}
	return self;
}

- (void) dealloc
{
	[scaleUpAction release];
	[scaleDownAction release];
	
	[super dealloc];
}

#pragma mark Utility

- (bool) setKnobPosition:(CGPoint) pos
{
	return NO;
}

#pragma mark Event Handlers

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if([self touch:touch hitsNode:self])
	{
		CGPoint local = [self convertTouchToNodeSpace:touch];
		[self setKnobPosition:local];
		[knob stopAllActions];
		[knob runAction:scaleUpAction];
		if(nil != moveSelector)
		{
			[target performSelector:moveSelector withObject:self];
		}
		return YES;
	}
	return NO;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint local = [self convertTouchToNodeSpace:touch];
	
	if([self setKnobPosition:local] && nil != moveSelector)
	{
		[target performSelector:moveSelector withObject:self];
	}
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	[knob stopAllActions];
	[knob runAction:scaleDownAction];
	if(nil != dropSelector)
	{
		[target performSelector:dropSelector withObject:self];
	}
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	[knob stopAllActions];
	[knob runAction:scaleDownAction];
}

#pragma mark Properties

- (GLubyte) opacity
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			return ((id<CCRGBAProtocol>)child).opacity;
		}
	}
	return 255;
}

- (void) setOpacity:(GLubyte) value
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			[((id<CCRGBAProtocol>)child) setOpacity:value];
		}
	}
}

- (ccColor3B) color
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			return ((id<CCRGBAProtocol>)child).color;
		}
	}
	return ccWHITE;
}

- (void) setColor:(ccColor3B) value
{
	for(CCNode* child in self.children)
	{
		if([child conformsToProtocol:@protocol(CCRGBAProtocol)])
		{
			[((id<CCRGBAProtocol>)child) setColor:value];
		}
	}
}

- (float) value
{
	return 0;
}

- (void) setValue:(float) value
{
	// Do nothing
}

@end


#pragma mark -
#pragma mark VerticalSlider

@implementation VerticalSlider

#pragma mark Object Management

- (id) initWithTrack:(CCNode*) trackIn
				knob:(CCNode*) knobIn
			 padding:(CGSize) padding
			  target:(id) targetIn
		moveSelector:(SEL) moveSelectorIn
		dropSelector:(SEL) dropSelectorIn
{
	if(nil != (self = [super initWithTrack:trackIn
									  knob:knobIn
								   padding:padding
									target:targetIn
							  moveSelector:moveSelectorIn
							  dropSelector:dropSelectorIn]))
	{
		CGSize knobSize = CGSizeMake(knob.contentSize.width * knob.scaleX, knob.contentSize.height * knob.scaleY);
		knobSize.width += padding.width*2;
		knobSize.height += padding.height*2;

		CGSize trackSize = CGSizeMake(track.contentSize.width * track.scaleX, track.contentSize.height * track.scaleY);
		trackSize.width += padding.width*2;
		trackSize.height += padding.height*2;

		CGSize combinedSize = CGSizeMake(knobSize.width > trackSize.width ? knobSize.width : trackSize.width,
										 knobSize.height > trackSize.height ? knobSize.height : trackSize.height);

		verticalMin = knobSize.height/2 - padding.height*2;
		verticalMax = trackSize.height - knobSize.height/2;
		horizontalLock = combinedSize.width/2;
		
		knob.anchorPoint = ccp(0.5f,0.5f);
		knob.position = ccp(horizontalLock, verticalMin);
		
		track.anchorPoint = ccp(0,0);
		track.position = ccp(combinedSize.width/2 - track.contentSize.width/2, 0);
	}
	return self;
}

#pragma mark Utility

- (bool) setKnobPosition:(CGPoint) position
{
	float y = position.y;
	if(y < verticalMin)
	{
		y = verticalMin;
	}
	if(y > verticalMax)
	{
		y = verticalMax;
	}
	CGPoint finalPosition = ccp(horizontalLock, y);
	if(finalPosition.x != knob.position.x || finalPosition.y != knob.position.y)
	{
		knob.position = finalPosition;
		return YES;
	}
	return NO;
}

#pragma mark Properties

- (float) value
{
	float spread = verticalMax - verticalMin;
	float position = knob.position.y - verticalMin;
	return position / spread;
}

- (void) setValue:(float) val
{
	float spread = verticalMax - verticalMin;
	float position = verticalMin + spread * val;
	knob.position = ccp(horizontalLock, position);
}

@end


#pragma mark -
#pragma mark HorizontalSlider

@implementation HorizontalSlider

#pragma mark Object Management

- (id) initWithTrack:(CCNode*) trackIn
				knob:(CCNode*) knobIn
			 padding:(CGSize) padding
			  target:(id) targetIn
		moveSelector:(SEL) moveSelectorIn
		dropSelector:(SEL) dropSelectorIn
{
	if(nil != (self = [super initWithTrack:trackIn
									  knob:knobIn
								   padding:padding
									target:targetIn
							  moveSelector:moveSelectorIn
							  dropSelector:dropSelectorIn]))
	{
		CGSize knobSize = CGSizeMake(knob.contentSize.width * knob.scaleX, knob.contentSize.height * knob.scaleY);
		knobSize.width += padding.width*2;
		knobSize.height += padding.height*2;
		
		CGSize trackSize = CGSizeMake(track.contentSize.width * track.scaleX, track.contentSize.height * track.scaleY);
		trackSize.width += padding.width*2;
		trackSize.height += padding.height*2;
		
		CGSize combinedSize = CGSizeMake(knobSize.width > trackSize.width ? knobSize.width : trackSize.width,
										 knobSize.height > trackSize.height ? knobSize.height : trackSize.height);
		
		horizontalMin = knobSize.width/2 - padding.width*2;
		horizontalMax = trackSize.width - knobSize.width/2;
		verticalLock = combinedSize.height/2;
		
		knob.anchorPoint = ccp(0.5f,0.5f);
		knob.position = ccp(horizontalMin, verticalLock);
		
		track.anchorPoint = ccp(0,0);
		track.position = ccp(0, combinedSize.height/2 - track.contentSize.height/2);
	}
	return self;
}

#pragma mark Utility

- (bool) setKnobPosition:(CGPoint) position
{
	float x = position.x;
	if(x < horizontalMin)
	{
		x = horizontalMin;
	}
	if(x > horizontalMax)
	{
		x = horizontalMax;
	}
	CGPoint finalPosition = ccp(x, verticalLock);
	if(finalPosition.x != knob.position.x || finalPosition.y != knob.position.y)
	{
		knob.position = finalPosition;
		return YES;
	}
	return NO;
}

#pragma mark Properties

- (float) value
{
	float spread = horizontalMax - horizontalMin;
	float position = knob.position.x - horizontalMin;
	return position / spread;
}

- (void) setValue:(float) val
{
	float spread = horizontalMax - horizontalMin;
	float position = horizontalMin + spread * val;
	knob.position = ccp(position, verticalLock);
}

@end
