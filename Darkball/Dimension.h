//
//  Dimension.h
//  Darkball
//
//  Created by Che-Wei Wang on 1/21/15.
//
//

#import <UIKit/UIKit.h>

@interface Dimension : UIView
-(void) setColor:(UIColor *)color;
@property UIColor* lineColor;
@property CGFloat lineWidth;
@property CGFloat dimLineOffsetX;

@property CGPoint targetPosition;
@property CGPoint ballPosition;

@end
