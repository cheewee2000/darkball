//
//  Crosshair.m
//  Darkball
//
//  Created by Che-Wei Wang on 12/30/14.
//
//

#import "Crosshair.h"

@implementation Crosshair

- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        startFrame=self.frame;
        
        self.clipsToBounds=NO;
        
        self.dotColor=[UIColor whiteColor];

        self.lineWidth = 2;
        
        
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
    //CGRect borderRect = CGRectInset(rect, _lineWidth , _lineWidth );
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat r,g,b,a;
    [self.dotColor getRed:&r green:&g blue:&b alpha:&a];

    CGContextSetRGBStrokeColor(context, r, g, b, a);
    CGContextSetRGBFillColor(context, r, g, b, a);

    CGContextSetLineWidth(context, _lineWidth);
     float dotSize=6;
     
     CGRect dot = CGRectInset(CGRectMake(rect.size.width*.5-dotSize*.5, rect.size.height*.5-dotSize*.5, dotSize, dotSize), _lineWidth , _lineWidth );
     //if(fill) CGContextFillEllipseInRect (context, borderRect);

    CGContextFillEllipseInRect(context, dot);
    CGContextFillPath(context);
 
//     //thin lines
//     CGContextSetLineWidth(context, _lineWidth*.05);
//     CGContextMoveToPoint(context, 0, self.frame.size.height*.5);    // This sets up the start point
//     CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height*.5); // This moves to the end point.
//     CGContextMoveToPoint(context, self.frame.size.width*.5,0);    // This sets up the start point
//     CGContextAddLineToPoint(context, self.frame.size.width*.5, self.frame.size.height); // This moves to the end point.
//     CGContextStrokePath(context);
//
//     //thick lines
//     CGContextSetLineWidth(context, _lineWidth*.08);
//     CGContextMoveToPoint(context, 0, self.frame.size.height*.5);    // This sets up the start point
//     CGContextAddLineToPoint(context, self.frame.size.width*.25, self.frame.size.height*.5); // This moves to the end point.
//   
//     CGContextMoveToPoint(context, self.frame.size.width*.75, self.frame.size.height*.5);    // This sets up the start point
//     CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height*.5); // This moves to the end point.
//     
//     CGContextMoveToPoint(context, self.frame.size.width*.5, 0);    // This sets up the start point
//     CGContextAddLineToPoint(context, self.frame.size.width*.5, self.frame.size.height*.25); // This moves to the end point.
//    
//     CGContextMoveToPoint(context, self.frame.size.width*.5, self.frame.size.height);    // This sets up the start point
//     CGContextAddLineToPoint(context, self.frame.size.width*.5, self.frame.size.height*.75); // This moves to the end point.
//     CGContextStrokePath(context);
    
 }

-(void) setColor:(UIColor *)color
{
    self.dotColor=color;
}

@end
