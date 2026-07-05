//
//  Sparkline.h
//  Darkball
//
//  Created by Che-Wei Wang on 12/14/14.
//
//

#import <UIKit/UIKit.h>

@interface Sparkline : UIView

@property (strong, atomic) NSArray *yValues;
@property (strong, atomic) NSArray *accuracyScore;
-(float)getAccuracyAverage;
@end