//
//  DUIDrawView.m
//  DUIDraw
//
//  Created by Caleb Cannon on 3/28/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import DistributedUI;


#import "DUIDrawView.h"



@interface DUIDrawView ()

@property (assign) CGContextRef bufferContext;
@property (readonly) CGImageRef bufferImage;

@property (strong) UIBezierPath *path;

@end

@implementation DUIDrawView

@synthesize bufferContext = _bufferContext;
@synthesize bufferImage = _bufferImage;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
	{
		self.penSize = 0.5;
		self.penColor = [UIColor redColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextDrawImage(UIGraphicsGetCurrentContext(), self.bounds, self.bufferImage);
	
	if (self.path)
	{
		[[self.penColor colorWithAlphaComponent:0.5] setStroke];
		[self.path stroke];
	}
}

- (CGImageRef) bufferImage
{
	if (_bufferImage)
		CGImageRelease(_bufferImage);
	_bufferImage = CGBitmapContextCreateImage(self.bufferContext);
	return _bufferImage;
}

- (CGContextRef) bufferContext
{
	if (!_bufferContext)
	{
		//Initialize the canvas size!
		CGSize canvasSize = self.frame.size;
		
		int bitsPerComponent	= 8;
		
		//Create the color space
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			
		//Create the context
		_bufferContext = CGBitmapContextCreate(NULL,
											   canvasSize.width,
											   canvasSize.height,
											   bitsPerComponent,
											   0,
											   colorSpace,
											   (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

		CGContextSetRGBFillColor(_bufferContext, 1, 1, 1, 1);
		CGContextFillRect(_bufferContext, self.bounds);
		
		CGColorSpaceRelease(colorSpace);
	}
	
	return _bufferContext;
}

- (void)setBufferContext:(CGContextRef)bufferContext
{
	_bufferContext = bufferContext;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.path = [UIBezierPath bezierPath];
	self.path.lineWidth = self.penSize;
	self.path.lineCapStyle = kCGLineCapRound;
	self.path.lineJoinStyle = kCGLineJoinRound;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UIImage *img = [UIImage imageNamed:@"Blob"];
	
	// Create a tinted copy of the blob image
	UIGraphicsBeginImageContext(img.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[self.penColor colorWithAlphaComponent:0.5] setFill];
	CGContextSetBlendMode(context, kCGBlendModeMultiply);
	CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
	CGContextDrawImage(context, rect, img.CGImage);
	CGContextClipToMask(context, rect, img.CGImage);
	CGContextFillRect(context, rect);
	CGContextAddRect(context, rect);
	CGContextDrawPath(context,kCGPathFill);
	UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	
	// Commit the drawing to the backing buffer
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];

	CGRect drawRect = CGRectMake(p.x-img.size.width/2.0*self.penSize,
								 p.y-img.size.width/2.0*self.penSize,
								 img.size.width*self.penSize,
								 img.size.height*self.penSize);
	
	UIGraphicsPushContext(self.bufferContext);
	[coloredImg drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:1.0];
	UIGraphicsPopContext();
	
	[self setNeedsDisplayInRect:drawRect];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Commit the drawing to the backing buffer
	UIGraphicsPushContext(self.bufferContext);
	[[self.penColor colorWithAlphaComponent:0.5] setStroke];
	[self.path stroke];
	UIGraphicsPopContext();
	
	[self setNeedsDisplayInRect:self.bounds];
	self.path = nil;
}

@end