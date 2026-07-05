//
//  Arc.m
//  Darkball
//
//  Created by Che-Wei Wang on 11/23/14.
//
//

#import "Arc.h"

@implementation Arc

- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        [self setClipsToBounds:NO];
        
    }
    return self;
}


 - (void)drawRect:(CGRect)rect
 {
     float lineWidth=2.0;
     CGContextRef context = UIGraphicsGetCurrentContext();
     CGContextAddArc(context, self.frame.size.width*.5 , self.frame.size.height*.5, self.frame.size.width*.5-lineWidth, M_PI, M_PI*2.0, NO);
     CGContextSetStrokeColorWithColor(context, [[UIColor colorWithWhite:.8 alpha:1] CGColor]);
     CGContextSetLineWidth(context, lineWidth);
     
     CGContextDrawPath(context, kCGPathStroke);
 }

@end
