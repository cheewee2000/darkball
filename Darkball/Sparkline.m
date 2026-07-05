//
//  Sparkline.m
//  Darkball
//
//  Created by Che-Wei Wang on 12/14/14.
//
//

#import "Sparkline.h"

@implementation Sparkline

@synthesize yValues;
@synthesize accuracyScore;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawBarGraphWithContext:(CGContextRef)ctx
{
    // Draw the bars
    int kBarWidth=self.frame.size.width/40.0;
    float maxBarHeight = self.frame.size.height;
    float maxValue = [[yValues valueForKeyPath:@"@max.integerValue"] integerValue];
    int nBars=(int)yValues.count;
    
    if(nBars>2){
        for (int i = nBars-1; i >=0; i--)
        {
            float barX = self.frame.size.width-(nBars-i) * kBarWidth * 1.5+kBarWidth/2.0;
            float barHeight = maxBarHeight * ([yValues[i] integerValue]-1)/maxValue;
            if(barHeight>0){
                CGRect barRect = CGRectMake(barX, maxBarHeight, kBarWidth, -barHeight);
                UIColor *c=[UIColor colorWithWhite:.8 alpha:1];
                if([yValues[i] integerValue]==maxValue)c=[UIColor colorWithRed:255/255 green:163/255.0 blue:0 alpha:1];
                [self drawBar:barRect context:ctx color:c];
            }
            if(barX<=kBarWidth)return;
        }
    }
}

- (void)drawBar:(CGRect)rect context:(CGContextRef)ctx color:(UIColor*)c
{
    CGContextBeginPath(ctx);
    CGContextSetFillColorWithColor(ctx, c.CGColor);
    CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawBarGraphWithContext:context];
}

-(float)getAccuracyAverage{

    float score=0;
    int count=0;
    for (int i = 0; i <(int)accuracyScore.count; i++)
    {
        if(accuracyScore[i]>0) {
            score+=[accuracyScore[i] floatValue];
            //NSLog(@"%f",score);
            count++;
        }
    }
    score=score/(float)count;
    //NSLog(@"%f",score);

    return score;
}
@end
