//
//  CCNode+ContentSize.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-19.
//

#import "CCNode+ContentSize.h"


@implementation CCNode (ContentSize)

- (void) setContentSizeFromChildren
{
	float minX = 1000000;
	float minY = 1000000;
	float maxX = -1000000;
	float maxY = -1000000;
	
	for(CCNode* node in children_)
	{
		float nextMinX = node.position.x - node.contentSize.width * node.scaleX * node.anchorPoint.x;
		float nextMaxX = nextMinX + node.contentSize.width * node.scaleX;
		float nextMinY = node.position.y - node.contentSize.height * node.scaleY * node.anchorPoint.y;
		float nextMaxY = nextMinY + node.contentSize.height * node.scaleY;
		
		if(nextMinX < minX)
		{
			minX = nextMinX;
		}
		if(nextMaxX > maxX)
		{
			maxX = nextMaxX;
		}
		if(nextMinY < minY)
		{
			minY = nextMinY;
		}
		if(nextMaxY > maxY)
		{
			maxY = nextMaxY;
		}
	}
	
	self.contentSize = CGSizeMake(maxX - minX, maxY - minY);
}

- (CGSize) minimalDimensionsForChildren
{
	CGSize size = CGSizeMake(0, 0);
	
	for(CCNode* node in children_)
	{
		if(node.contentSize.width * node.scaleX > size.width)
		{
			size.width = node.contentSize.width * node.scaleX;
		}
		if(node.contentSize.height * node.scaleY > size.height)
		{
			size.height = node.contentSize.height * node.scaleY;
		}
	}
	
	return size;
}

@end
