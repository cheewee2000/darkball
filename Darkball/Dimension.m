//
//  Dimension.m
//  Darkball
//
//  Created by Che-Wei Wang on 1/21/15.
//
//

#import "Dimension.h"

@implementation Dimension


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    //CGRect borderRect = CGRectInset(rect, _lineWidth , _lineWidth );
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat r,g,b,a;
    [_lineColor getRed:&r green:&g blue:&b alpha:&a];
    
    CGContextSetRGBStrokeColor(context, r, g, b, a);
    CGContextSetRGBFillColor(context, r, g, b, a);
    
    
    CGContextSetLineWidth(context, _lineWidth);
    float dotSize=5;
    float lineExtention=10;

    
    CGRect targetDot = CGRectInset(CGRectMake(_targetPosition.x-dotSize*.5,_targetPosition.y-dotSize*.5, dotSize, dotSize), _lineWidth , _lineWidth );
    CGContextFillEllipseInRect(context, targetDot);
    CGContextFillPath(context);
    
    CGRect targetTick = CGRectInset(CGRectMake(_targetPosition.x-_dimLineOffsetX-dotSize*.5,_targetPosition.y-dotSize*.5, dotSize, dotSize), _lineWidth , _lineWidth );
    CGContextFillEllipseInRect(context, targetTick);
    CGContextFillPath(context);
    
    
    CGRect ballDot = CGRectInset(CGRectMake(_ballPosition.x-dotSize*.5,_ballPosition.y-dotSize*.5, dotSize, dotSize), _lineWidth , _lineWidth );
    CGContextFillEllipseInRect(context, ballDot);
    CGContextFillPath(context);
    
    CGRect ballTick = CGRectInset(CGRectMake(_ballPosition.x-_dimLineOffsetX-dotSize*.5,_ballPosition.y-dotSize*.5, dotSize, dotSize), _lineWidth , _lineWidth );
    CGContextFillEllipseInRect(context, ballTick);
    CGContextFillPath(context);
    
    
    //thin lines
    CGContextSetLineWidth(context, _lineWidth*.5);
    CGContextMoveToPoint(context, _targetPosition.x -_dimLineOffsetX-lineExtention ,_targetPosition.y);    // This sets up the start point
    CGContextAddLineToPoint(context, _targetPosition.x-lineExtention, _targetPosition.y); // This moves to the end point.

    CGContextMoveToPoint(context, _ballPosition.x -_dimLineOffsetX-lineExtention ,_ballPosition.y);    // This sets up the start point
    CGContextAddLineToPoint(context, _ballPosition.x-lineExtention, _ballPosition.y); // This moves to the end point.

    CGContextStrokePath(context);
    
    //thick lines
    CGContextSetLineWidth(context, _lineWidth);
    if(_ballPosition.y>_targetPosition.y)
    {
        CGContextMoveToPoint(context, _targetPosition.x-_dimLineOffsetX, _targetPosition.y -lineExtention);    // This sets up the start point
        CGContextAddLineToPoint(context, _targetPosition.x-_dimLineOffsetX, _ballPosition.y +lineExtention); // This moves to the end point.
    }
    else{
        CGContextMoveToPoint(context, _targetPosition.x-_dimLineOffsetX, _targetPosition.y +lineExtention);    // This sets up the start point
        CGContextAddLineToPoint(context, _targetPosition.x-_dimLineOffsetX, _ballPosition.y -lineExtention); // This moves to the end point.
        
    }

    CGContextStrokePath(context);

}

-(void) setColor:(UIColor *)c
{
    _lineColor=c;
}


@end
