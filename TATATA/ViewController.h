//
//  ViewController.h
//  VolumeSnap
//
//  Created by Randall Brown on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Dots.h"
#import <GameKit/GameKit.h>
#import "MachTimer.h"
#import "Arc.h"
#import "Sparkline.h"
#import "Crosshair.h"
//#import "Screener.h"

#import "Dimension.h"
#import "UICountingLabel.h"

@interface ViewController : UIViewController <GKGameCenterControllerDelegate,UIScrollViewDelegate>

{
    NSDictionary *currentTrial;
    long trialCount;
    
    int screenWidth,screenHeight;
    int trialSequence;
    NSMutableArray* trialArray;
    NSString *trialArrayDataFile;
    
    Arc * arc;
    //Dots *startZoneFlash;
    Dots *testBall;

    Dots *ball;
    Crosshair *dotInDot;
    Dots *catchZone;
    Dots *catchZoneCenter;
    //Dots *catchZoneFlash;
    Crosshair *crosshair;
    UILabel * ballAnnotation;
    Dimension *dimension;
    
    //UIView *catchZoneAnnotation;
    UICountingLabel *catchZoneLabel;
    double ballAlpha;
    
    float startY;
    float endY;
    
    UILabel * scoreLabel;

    UILabel * bestLabel;

    UILabel * accuracyLabel;

    UILabel * trialCountLabel;
 
    UIButton *playButton;
    
    UIView * midMarkL;
    UIView * midMarkR;
    UIView * midMarkLine;

    UILabel * currentScoreLabel;

    float flashT;
    float lastFlashT;
    UICountingLabel * midMarkLabel;
    
    UIColor *bgColor;
    UIColor *fgColor;
    UIColor *flashColor;
    UIColor *strokeColor;

    //config file
    float flashDuration;
    float accuracyStart;
    float accuracyIncrement;
    float accuracyMax;
    float ballDiameter;
    float nTrialsInStage;
    float trueD1Duration;
    float trueD2Duration;
    float levelAccuracy;
    
    //float trueTimerGoal;
    int d1Frames;
    int d2Frames;
    float d1Duration;
    float d2Duration;
    //float catchZoneDiameter;
    int frameCount;
    BOOL dropBall;
    
    
    UIButton *gameCenterButton;
    UIButton *infoButton;

    UIButton *showScoreboardButton;
    UIButton *catchZoneButton;
    
    float dimAlpha;
    BOOL touched;
    float touchX,touchY;
    
    BOOL allowBallResize;
    
    float trialDelay;

    //Screener *screener;
    int introHeight;

#pragma mark - timing
    NSTimeInterval elapsed;
    NSTimeInterval timerGoal;
    MachTimer* aTimer;
    NSTimeInterval touchLength;
    NSTimeInterval touchStartTime;

    
    #pragma mark - points
    int best;
    int lastScore;
    float accuracyScore;
    int currentLevel;
    Sparkline *scoreGraph;
    NSMutableArray *scoreHistory;
    NSString *scoreHistoryDataFile;
    NSMutableArray *accuracyHistory;
    NSString *accuracyHistoryDataFile;
    
    #pragma mark - intro
    UIView *intro;
    UILabel* introTitle;
    UILabel* introSubtitle;
    UILabel* introParagraph;
    UILabel* credits;

    UIButton* feedbackButton;
//    BOOL showIntro;
//    BOOL showSurvey;

    
    int nExampleFails;
    
    UIScrollView *scrollView;
    
    //timer
    double currentFrameTimestamp;
    double lastFrameTimestamp;
    float CATransactionDelay;

    CADisplayLink *displayLink;
    float frameOffset;
    int droppedFrames;
    BOOL secondFlash;
    
    BOOL shouldAutoStart;
}
@property int currentPage;

@property BOOL gameCenterEnabled;
@property NSString *leaderboardIdentifier;



@end
