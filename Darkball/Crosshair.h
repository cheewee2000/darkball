//
//  Crosshair.h
//  Darkball
//
//  Created by Che-Wei Wang on 12/30/14.
//
//

#import <UIKit/UIKit.h>

@interface Crosshair : UIView
{
    bool fill;
    int startX;
    int startY;
    CGRect startFrame;
    
}
@property UIColor* dotColor;
@property CGFloat lineWidth;
-(void) setColor:(UIColor *)color;

@end
