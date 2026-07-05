//
//  UIView+Dots.h
//  BlindStopwatch
//
//  Created by Che-Wei Wang on 9/8/14.
//
//

#import <UIKit/UIKit.h>

@interface Dots:UIView
{
    bool fill;
    int startX;
    int startY;
    CGRect startFrame;
    
    NSArray* stars;
    
}

-(void) setFill:(bool) b;
-(void) setText:(NSString *) s level:(NSString *)l;
-(void) resetPosition;
//- (void) animateAlongPath:(CGRect) frame rotate:(float) radians speed:(float)speed;
//-(void) setStars:(int)s;
-(void) setColor:(UIColor *)color;

@property UILabel *label;
//@property UILabel *level;
@property float *labelValue;
@property UIColor* dotColor;
@property CGFloat lineWidth;

@end
