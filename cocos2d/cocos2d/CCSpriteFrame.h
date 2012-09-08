/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2008-2011 Ricardo Quesada
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
 *
 */

#import <Foundation/Foundation.h>
#import "CCNode.h"
#import "CCProtocols.h"

/** A CCSpriteFrame has:
	- texture: A CCTexture2D that will be used by the CCSprite
	- rectangle: A rectangle of the texture


 You can modify the frame of a CCSprite by doing:

	CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:texture rect:rect offset:offset];
	[sprite setDisplayFrame:frame];
 */
@interface CCSpriteFrame : NSObject <NSCopying>
{
	CGRect			rect_;
	CGRect			rectInPixels_;
	BOOL			rotated_;
    CGPoint			offset_;
	CGPoint			offsetInPixels_;
	CGSize			originalSize_;
	CGSize			originalSizeInPixels_;
	CCTexture2D		*texture_;
	NSString		*textureFilename_;
}
/** rect of the frame in points. If it is updated, then rectInPixels will be updated too. */
@property (nonatomic,readwrite) CGRect rect;

/** rect of the frame in pixels. If it is updated, then rect (points) will be udpated too. */
@property (nonatomic,readwrite) CGRect rectInPixels;

/** whether or not the rect of the frame is rotated ( x = x+width, y = y+height, width = height, height = width ) */
@property (nonatomic,readwrite) BOOL rotated;

/** offset of the frame in points */
@property (nonatomic,readwrite) CGPoint offset;

/** offset of the frame in pixels */
@property (nonatomic,readwrite) CGPoint offsetInPixels;

/** original size of the trimmed image in points */
@property (nonatomic,readwrite) CGSize originalSize;

/** original size of the trimmed image in pixels */
@property (nonatomic,readwrite) CGSize originalSizeInPixels;

/** texture of the frame */
@property (nonatomic, retain, readwrite) CCTexture2D *texture;

/** texture file name of the frame */
@property (nonatomic, retain, readonly) NSString *textureFilename;

/** Create a CCSpriteFrame with a texture, rect in points.
 It is assumed that the frame was not trimmed.
 */
+(id) frameWithTexture:(CCTexture2D*)texture rect:(CGRect)rect;

/** Create a CCSpriteFrame with a texture filename, rect in points.
 It is assumed that the frame was not trimmed.
 */
+(id) frameWithTextureFilename:(NSString*)filename rect:(CGRect)rect;

/** Create a CCSpriteFrame with a texture, rect, rotated, offset and originalSize in pixels.
 The originalSize is the size in pixels of the frame before being trimmed.
 */
+(id) frameWithTexture:(CCTexture2D*)texture rectInPixels:(CGRect)rect rotated:(BOOL)rotated offset:(CGPoint)offset originalSize:(CGSize)originalSize;


/** Create a CCSpriteFrame with a texture filename, rect, rotated, offset and originalSize in pixels.
 The originalSize is the size in pixels of the frame before being trimmed.
 */
+(id) frameWithTextureFilename:(NSString*)filename rectInPixels:(CGRect)rect rotated:(BOOL)rotated offset:(CGPoint)offset originalSize:(CGSize)originalSize;


/** Initializes a CCSpriteFrame with a texture, rect in points;
 It is assumed that the frame was not trimmed.
 */
-(id) initWithTexture:(CCTexture2D*)texture rect:(CGRect)rect;

/** Initializes a CCSpriteFrame with a texture filename, rect in points;
 It is assumed that the frame was not trimmed.
 */
-(id) initWithTextureFilename:(NSString*)filename rect:(CGRect)rect;


/** Initializes a CCSpriteFrame with a texture, rect, rotated, offset and originalSize in pixels.
 The originalSize is the size in pixels of the frame before being trimmed.
 */
-(id) initWithTexture:(CCTexture2D*)texture rectInPixels:(CGRect)rect rotated:(BOOL)rotated offset:(CGPoint)offset originalSize:(CGSize)originalSize;

/** Initializes a CCSpriteFrame with a texture, rect, rotated, offset and originalSize in pixels.
 The originalSize is the size in pixels of the frame before being trimmed.

 @since v1.1
 */
-(id) initWithTextureFilename:(NSString*)filename rectInPixels:(CGRect)rect rotated:(BOOL)rotated offset:(CGPoint)offset originalSize:(CGSize)originalSize;

@end

