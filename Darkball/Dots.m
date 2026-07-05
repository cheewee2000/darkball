//
//  UIView+Dots.m
//  BlindStopwatch
//
//  Created by Che-Wei Wang on 9/8/14.
//
//

#import "Dots.h"

@implementation Dots:UIView 

- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        startFrame=self.frame;

        self.clipsToBounds=NO;

        self.dotColor=[UIColor whiteColor];
        
        self.label=[[UILabel alloc] initWithFrame:CGRectMake(0, 42, 100, 20)];
        self.label.text=@"";
        self.label.textAlignment = NSTextAlignmentLeft;
        [self.label setTransform:CGAffineTransformMakeRotation(M_PI *.25)];
        [self addSubview:self.label];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.lineWidth = 2;

        
    }
    return self;
}






- (void)drawRect:(CGRect)rect
{
    CGRect borderRect = CGRectInset(rect, _lineWidth , _lineWidth );
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat r,g,b,a;
    [self.dotColor getRed:&r green:&g blue:&b alpha:&a];
    
    CGContextSetRGBStrokeColor(context, r, g, b, a);
    CGContextSetRGBFillColor(context, r, g, b, a);

    CGContextSetLineWidth(context, _lineWidth);
    if(fill) CGContextFillEllipseInRect (context, borderRect);
    CGContextStrokeEllipseInRect(context, borderRect);
    CGContextFillPath(context);
}
-(void) resetPosition
{
    self.frame=startFrame;
    [self setNeedsDisplay];
}

-(void) setFill:(bool) b
{
    fill=b;
    [self setNeedsDisplay];
}
-(void) setColor:(UIColor *)color
{
    self.dotColor=color;
    for(int i=0; i<[stars count]; i++){
        UIImageView*s=[stars objectAtIndex:i];
        s.tintColor=color;
    }
    self.label.textColor=color;
}
-(void) setText:(NSString *) s level:(NSString *)l
{
    self.label.text=s;
    self.label.alpha=1.0;
    [self setNeedsDisplay];
}



@end
