//
//  Slider.m
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "Slider.h"


@interface Slider ()

@property(nonatomic, readwrite, assign) BOOL touchInProgress;
@property(nonatomic, readwrite, assign) CCNode* track;
@property(nonatomic, readwrite, assign) CCNode* knob;

@property(nonatomic, readwrite, assign) id target;
@property(nonatomic, readwrite, assign) SEL moveSelector;
@property(nonatomic, readwrite, assign) SEL dropSelector;

@property(nonatomic, readwrite, retain) CCScaleTo* scaleUpAction;
@property(nonatomic, readwrite, retain) CCScaleTo* scaleDownAction;

@end


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
		self.target = targetIn;
		self.moveSelector = moveSelectorIn;
		self.dropSelector = dropSelectorIn;
		
		self.track = trackIn;
		[self addChild:self.track z:10];
		
		self.knob = knobIn;
		[self addChild:self.knob z:20];

		self.scaleUpAction = [CCScaleBy actionWithDuration:0.1f scale:1.2f];
		self.scaleDownAction = [CCSequence actionOne:[CCScaleBy actionWithDuration:0.02f scale:1.1f]
											 two:[CCScaleTo actionWithDuration:0.05f scaleX:self.knob.scaleX scaleY:self.knob.scaleY]];

		CGSize knobSize = CGSizeMake(self.knob.contentSize.width * self.knob.scaleX, self.knob.contentSize.height * self.knob.scaleY);
		CGSize trackSize = CGSizeMake(self.track.contentSize.width * self.track.scaleX, self.track.contentSize.height * self.track.scaleY);
		CGSize combinedSize = CGSizeMake(knobSize.width > trackSize.width ? knobSize.width : trackSize.width,
										 knobSize.height > trackSize.height ? knobSize.height : trackSize.height);
		combinedSize.width += padding.width*2;
		combinedSize.height += padding.height*2;
		
		self.contentSize = combinedSize;
		self.touchPriority = 0;
		self.targetedTouches = YES;
		self.swallowTouches = YES;
		self.isTouchEnabled = YES;
		self.ignoreAnchorPointForPosition = NO;
		self.anchorPoint = ccp(0.5f, 0.5f);		

        __block Slider* blockSelf = self;

        self.onTouchStart = ^BOOL (CGPoint pos)
        {
            if(!blockSelf.touchInProgress && [blockSelf pointHitsSelf:pos])
            {
                blockSelf.touchInProgress = YES;
                [blockSelf setKnobPosition:pos];
                [blockSelf.knob stopAllActions];
                [blockSelf.knob runAction:blockSelf.scaleUpAction];
                if(nil != blockSelf.moveSelector)
                {
                    [blockSelf.target performSelector:blockSelf.moveSelector withObject:blockSelf];
                }
                return YES;
            }
            return NO;
        };

        self.onTouchMove =  ^BOOL (CGPoint pos)
        {
            if(blockSelf.touchInProgress && [blockSelf setKnobPosition:pos] && nil != blockSelf.moveSelector)
            {
                [blockSelf.target performSelector:blockSelf.moveSelector withObject:blockSelf];
                return YES;
            }
            return NO;
        };

        self.onTouchEnd =  ^BOOL (CGPoint pos)
        {
            blockSelf.touchInProgress = NO;
            [blockSelf.knob stopAllActions];
            [blockSelf.knob runAction:blockSelf.scaleDownAction];
            if(nil != blockSelf.dropSelector)
            {
                [blockSelf.target performSelector:blockSelf.dropSelector withObject:blockSelf];
            }
            return NO;
        };

        self.onTouchCancel =  ^BOOL (CGPoint pos)
        {
            blockSelf.touchInProgress = NO;
            [blockSelf.knob stopAllActions];
            [blockSelf.knob runAction:blockSelf.scaleDownAction];
            return NO;
        };
	}
	return self;
}

- (void) dealloc
{
	[_scaleUpAction release];
	[_scaleDownAction release];
	
	[super dealloc];
}

#pragma mark Utility

- (bool) setKnobPosition:(__unused CGPoint) pos
{
	return NO;
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

- (void) setValue:(__unused float) value
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
		CGSize knobSize = CGSizeMake(self.knob.contentSize.width * self.knob.scaleX, self.knob.contentSize.height * self.knob.scaleY);
		knobSize.width += padding.width*2;
		knobSize.height += padding.height*2;

		CGSize trackSize = CGSizeMake(self.track.contentSize.width * self.track.scaleX, self.track.contentSize.height * self.track.scaleY);
		trackSize.width += padding.width*2;
		trackSize.height += padding.height*2;

		CGSize combinedSize = CGSizeMake(knobSize.width > trackSize.width ? knobSize.width : trackSize.width,
										 knobSize.height > trackSize.height ? knobSize.height : trackSize.height);

		verticalMin = knobSize.height/2 - padding.height*2;
		verticalMax = trackSize.height - knobSize.height/2;
		horizontalLock = combinedSize.width/2;
		
		self.knob.anchorPoint = ccp(0.5f,0.5f);
		self.knob.position = ccp(horizontalLock, verticalMin);
		
		self.track.anchorPoint = ccp(0,0);
		self.track.position = ccp(combinedSize.width/2 - self.track.contentSize.width/2, 0);
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
	if(finalPosition.x != self.knob.position.x || finalPosition.y != self.knob.position.y)
	{
		self.knob.position = finalPosition;
		return YES;
	}
	return NO;
}

#pragma mark Properties

- (float) value
{
	float spread = verticalMax - verticalMin;
	float position = self.knob.position.y - verticalMin;
	return position / spread;
}

- (void) setValue:(float) val
{
	float spread = verticalMax - verticalMin;
	float position = verticalMin + spread * val;
	self.knob.position = ccp(horizontalLock, position);
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
		CGSize knobSize = CGSizeMake(self.knob.contentSize.width * self.knob.scaleX, self.knob.contentSize.height * self.knob.scaleY);
		knobSize.width += padding.width*2;
		knobSize.height += padding.height*2;
		
		CGSize trackSize = CGSizeMake(self.track.contentSize.width * self.track.scaleX, self.track.contentSize.height * self.track.scaleY);
		trackSize.width += padding.width*2;
		trackSize.height += padding.height*2;
		
		CGSize combinedSize = CGSizeMake(knobSize.width > trackSize.width ? knobSize.width : trackSize.width,
										 knobSize.height > trackSize.height ? knobSize.height : trackSize.height);
		
		horizontalMin = knobSize.width/2 - padding.width*2;
		horizontalMax = trackSize.width - knobSize.width/2;
		verticalLock = combinedSize.height/2;
		
		self.knob.anchorPoint = ccp(0.5f,0.5f);
		self.knob.position = ccp(horizontalMin, verticalLock);
		
		self.track.anchorPoint = ccp(0,0);
		self.track.position = ccp(0, combinedSize.height/2 - self.track.contentSize.height/2);
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
	if(finalPosition.x != self.knob.position.x || finalPosition.y != self.knob.position.y)
	{
		self.knob.position = finalPosition;
		return YES;
	}
	return NO;
}

#pragma mark Properties

- (float) value
{
	float spread = horizontalMax - horizontalMin;
	float position = self.knob.position.x - horizontalMin;
	return position / spread;
}

- (void) setValue:(float) val
{
	float spread = horizontalMax - horizontalMin;
	float position = horizontalMin + spread * val;
	self.knob.position = ccp(position, verticalLock);
}

@end
