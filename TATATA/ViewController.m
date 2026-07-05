#import "ViewController.h"
#import <sys/utsname.h> // import it in your header or implementation file.

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define ARC4RANDOM_MAX 0x100000000

//#define TESTING

@interface ViewController () {
    
}
@end

@implementation ViewController


- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
   [super viewDidLoad];
    
    screenHeight=self.view.frame.size.height;
    screenWidth=self.view.frame.size.width;
    bgColor=[UIColor colorWithRed:14/255.0 green:14/255.0 blue:15/255.0 alpha:1];
    fgColor=[UIColor colorWithRed:255/255 green:163/255.0 blue:0 alpha:1];
    flashColor=[UIColor colorWithWhite:1 alpha:1];
    strokeColor=[UIColor colorWithWhite:.8 alpha:1];

    surveyHeight=4000;
    questionnaireHeight=1800;
    screeningHeight=750;
    introHeight=850;

    surveyHeights = @[@750,@1800,@4000];

    allowBallResize=false;
    dimAlpha=.04;
    
    aTimer = [MachTimer timer];
    
    flashT=.5;
    frameCount=0;
    
    [self authenticateLocalPlayer];

    self.view.backgroundColor=bgColor;
    
   #pragma mark - Persistent Variables
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"best"] == nil) best=0;
    else best = (int)[defaults integerForKey:@"best"];
    
    if([defaults objectForKey:@"lastScore"] == nil) lastScore=0;
    else lastScore = (int)[defaults integerForKey:@"lastScore"];
    
    if([defaults objectForKey:@"showIntro1"] == nil) [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showIntro1"];
//    else showIntro = (int)[defaults integerForKey:@"showIntro1"];
//
//    if([defaults objectForKey:@"showSurvey"] == nil) showSurvey=false;
//    else showSurvey = (int)[defaults integerForKey:@"showSurvey"];


    

#pragma mark - Ball
    startY=screenHeight*.5-190.0;
    endY=screenHeight*.5+190.0;
    
    catchZone=[[Dots alloc] initWithFrame:CGRectMake(0,0, 88, 88)];
    catchZone.center=CGPointMake(screenWidth*.5, screenHeight*.5);
    catchZone.backgroundColor = [UIColor clearColor];
    catchZone.alpha=0;
    catchZone.lineWidth=0;

    [catchZone setColor:strokeColor];
    [catchZone setFill:NO];
    [self.view addSubview:catchZone];
    

    crosshair=[[Crosshair alloc] initWithFrame:CGRectMake(0,0, 80, 80)];
    crosshair.center=CGPointMake(catchZone.frame.size.width*.5, catchZone.frame.size.height*.5);
    crosshair.backgroundColor = [UIColor clearColor];
    crosshair.alpha=0;
    [crosshair setColor:[UIColor blackColor]];
    [catchZone addSubview:crosshair];
    
    
//    catchZoneCenter=[[Dots alloc] initWithFrame:CGRectMake(0,0, 8, 8)];
//    catchZoneCenter.center=catchZone.center;
//    catchZoneCenter.backgroundColor = [UIColor clearColor];
//    catchZoneCenter.alpha=0;
//    [catchZoneCenter setColor:strokeColor];
//    [catchZoneCenter setFill:YES];
//    [self.view addSubview:catchZoneCenter];
//    

    ballAlpha=.9;
    ball=[[Dots alloc] initWithFrame:CGRectMake(0, 0, 85, 85)];
    ball.center=CGPointMake(screenWidth*.5, startY);
    ball.backgroundColor = [UIColor clearColor];
    ball.alpha=0;
    [ball setColor:strokeColor];
    [ball setFill:YES];
    //ball.lineWidth=ball.frame.size.width*.5-2;
    [self.view addSubview:ball];
    [self.view bringSubviewToFront:ball];
    
    dotInDot=[[Crosshair alloc] initWithFrame:CGRectMake(0,0, 80, 80)];
    dotInDot.center=CGPointMake(ball.frame.size.width*.5, ball.frame.size.height*.5);
    dotInDot.backgroundColor = [UIColor clearColor];
    dotInDot.alpha=.3;
    [dotInDot setColor:[UIColor blackColor]];
    [ball addSubview:dotInDot];
    
    
    testBall=[[Dots alloc] initWithFrame:CGRectMake(0, 0, 385, 385)];
    testBall.center=CGPointMake(screenWidth*.5, startY);
    testBall.backgroundColor = [UIColor clearColor];
    testBall.alpha=0;
    [testBall setColor:strokeColor];
    [testBall setFill:YES];    
    [self.view  addSubview:testBall];
    [self.view  bringSubviewToFront:testBall];
    
    
    
    
    ballAnnotation=[[UILabel alloc] initWithFrame:CGRectMake(0,0,150,80)];
    ballAnnotation.backgroundColor=[UIColor clearColor];
    ballAnnotation.textAlignment=NSTextAlignmentRight;
    ballAnnotation.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:18];
    ballAnnotation.textColor=strokeColor;
    ballAnnotation.alpha=0;
    [self.view addSubview:ballAnnotation];
    
    
    dimension=[[Dimension alloc] initWithFrame:self.view.frame];
    dimension.backgroundColor=[UIColor clearColor];
    dimension.targetPosition=CGPointMake(screenWidth*.5, endY);
    dimension.lineWidth=1;
    [dimension setColor:strokeColor];
    dimension.alpha=0;
    [self.view addSubview:dimension];
    
    
    //catchzone diameter label
    catchZoneLabel=[[UICountingLabel alloc] initWithFrame:CGRectMake(screenWidth*.5,endY-120, 120, 115)];
    catchZoneLabel.backgroundColor=[UIColor clearColor];
    catchZoneLabel.textAlignment=NSTextAlignmentRight;
    catchZoneLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:18];
    catchZoneLabel.textColor=strokeColor;
    //catchZoneLabel.text=@"±0.000s";
    catchZoneLabel.format = @"%.1f%%";
    catchZoneLabel.method = UILabelCountingMethodLinear;

    catchZoneLabel.alpha=0;
    
    int dh=45;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.0, catchZoneLabel.frame.size.height)];
    [path addLineToPoint:CGPointMake(dh, catchZoneLabel.frame.size.height-dh)];
    [path addLineToPoint:CGPointMake(catchZoneLabel.frame.size.width, catchZoneLabel.frame.size.height-dh)];

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [path CGPath];
    shapeLayer.strokeColor = [strokeColor CGColor];
    shapeLayer.lineWidth = 0.5;
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    [catchZoneLabel.layer addSublayer:shapeLayer];
    
    [self.view addSubview:catchZoneLabel];
    [self.view sendSubviewToBack:catchZoneLabel];


//    UIBezierPath *circle = [UIBezierPath bezierPath];
//    [circle addArcWithCenter:CGPointMake(0.0, catchZone.frame.size.height)
//                    radius:2.0
//                startAngle:0.0
//                  endAngle:M_PI * 2.0
//                 clockwise:YES];
//
//    CAShapeLayer *circleLayer = [CAShapeLayer layer];
//    circleLayer.path = [circle CGPath];
//    circleLayer.strokeColor = [[UIColor clearColor] CGColor];
//    circleLayer.fillColor = [strokeColor CGColor];
//    [catchZone.layer addSublayer:circleLayer];

    
    
    
    
    
    arc=[[Arc alloc] initWithFrame:CGRectMake(0,0, 88,88)];
    arc.backgroundColor=[UIColor clearColor];
    arc.center=ball.center;
    [self.view addSubview:arc];
    arc.alpha=dimAlpha;
    

#pragma mark - Labels

    int labelHeight=190;
    int labelOffset=110;
    
    currentScoreLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, screenWidth, labelHeight)];
    //currentScoreLabel.center=CGPointMake(screenWidth/2.0, screenHeight/2.0);
    currentScoreLabel.center=CGPointMake(screenWidth/2.0, screenHeight*.5-labelOffset-labelHeight*.25);

    currentScoreLabel.text=@"0";
    currentScoreLabel.textAlignment = NSTextAlignmentCenter;
    currentScoreLabel.backgroundColor = [UIColor clearColor];
    currentScoreLabel.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:78];
    currentScoreLabel.textColor=strokeColor;
    currentScoreLabel.alpha=0;
    [self.view addSubview:currentScoreLabel];
    
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.delegate = self;
    [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, screenHeight*1.5)];
    [self.view addSubview:scrollView];

    catchZoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [catchZoneButton addTarget:self
                        action:@selector(buttonPressed)
              forControlEvents:UIControlEventTouchUpInside];
    catchZoneButton.frame=CGRectMake(0, 0, ball.frame.size.width*1.25, ball.frame.size.height*1.25);
    catchZoneButton.center=CGPointMake(screenWidth*.5, screenHeight*.5);
    catchZoneButton.backgroundColor=[UIColor clearColor];
    
    [scrollView addSubview:catchZoneButton];
    


    
    scoreLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, screenWidth, labelHeight)];
    scoreLabel.center=CGPointMake(screenWidth/2.0, screenHeight*.5-labelOffset-labelHeight*.25);
    scoreLabel.text=@"0";
    scoreLabel.textAlignment = NSTextAlignmentCenter;
    scoreLabel.backgroundColor = [UIColor clearColor];
    scoreLabel.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:78];
    scoreLabel.textColor=strokeColor;
    scoreLabel.alpha=0;
    [scrollView addSubview:scoreLabel];
    
    UILabel* scoreLabelLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 100, 40)];
    //scoreLabelLabel.center=CGPointMake(screenWidth/2.0, scoreLabel.center.y+80);
    scoreLabelLabel.center=CGPointMake(scoreLabel.frame.size.width/2.0, scoreLabel.frame.size.height-scoreLabelLabel.frame.size.height+20);
    scoreLabelLabel.text=@"SCORE";
    scoreLabelLabel.textAlignment = NSTextAlignmentCenter;
    scoreLabelLabel.backgroundColor = [UIColor clearColor];
    scoreLabelLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    scoreLabelLabel.textColor=strokeColor;
    scoreLabelLabel.alpha=1;
    [scoreLabel addSubview:scoreLabelLabel];
    
    UILabel* scoreLabelLine=[[UILabel alloc] initWithFrame:CGRectMake(0,0, scoreLabelLabel.frame.size.width, .5)];
    scoreLabelLine.backgroundColor = strokeColor;
    [scoreLabelLabel addSubview:scoreLabelLine];
    
    scoreGraph=[[Sparkline alloc] initWithFrame:CGRectMake(0,-20, scoreLabelLabel.frame.size.width, 20)];
    [scoreLabelLabel addSubview:scoreGraph];

    
    bestLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, screenWidth, labelHeight)];
    bestLabel.center=CGPointMake(screenWidth*.5, screenHeight*.5+labelOffset);
    bestLabel.text=@"0";
    bestLabel.textAlignment = NSTextAlignmentCenter;
    bestLabel.backgroundColor = [UIColor clearColor];
    bestLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:78];
    bestLabel.textColor=strokeColor;
    bestLabel.alpha=0;
    [scrollView addSubview:bestLabel];
    
    UILabel* bestLabelLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 100, 40)];
    //bestLabelLabel.center=CGPointMake(bestLabel.frame.size.width*.5, bestLabel.frame.size.height);
    bestLabelLabel.center=CGPointMake(bestLabel.frame.size.width/2.0, bestLabel.frame.size.height-bestLabelLabel.frame.size.height+20);
    bestLabelLabel.text=@"BEST";
    bestLabelLabel.textAlignment = NSTextAlignmentCenter;
    bestLabelLabel.backgroundColor = [UIColor clearColor];
    bestLabelLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    bestLabelLabel.textColor=strokeColor;
    bestLabelLabel.alpha=1;
    [bestLabelLabel setUserInteractionEnabled:NO];
    [bestLabel addSubview:bestLabelLabel];
    
    UILabel* bestLabelLine=[[UILabel alloc] initWithFrame:CGRectMake(0,0, bestLabelLabel.frame.size.width, .5)];
    bestLabelLine.backgroundColor = strokeColor;
    [bestLabelLabel addSubview:bestLabelLine];
    
    
    
    labelHeight=120;
    
    accuracyLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, screenWidth, labelHeight)];
    accuracyLabel.center=CGPointMake(screenWidth*.5, screenHeight);
    accuracyLabel.text=@"0";
    accuracyLabel.textAlignment = NSTextAlignmentCenter;
    accuracyLabel.backgroundColor = [UIColor clearColor];
    accuracyLabel.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:39];
    accuracyLabel.textColor=strokeColor;
    accuracyLabel.alpha=0;
    [scrollView addSubview:accuracyLabel];
    
    UILabel* accuracyLabelLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 100, 40)];
    accuracyLabelLabel.center=CGPointMake(accuracyLabel.frame.size.width/2.0, accuracyLabel.frame.size.height/2.0+labelHeight*.5);
    accuracyLabelLabel.text=@"ACCURACY";
    accuracyLabelLabel.textAlignment = NSTextAlignmentCenter;
    accuracyLabelLabel.backgroundColor = [UIColor clearColor];
    accuracyLabelLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    accuracyLabelLabel.textColor=strokeColor;
    accuracyLabelLabel.alpha=1;
    [accuracyLabelLabel setUserInteractionEnabled:NO];
    [accuracyLabel addSubview:accuracyLabelLabel];
    
    UILabel* accuracyLabelLine=[[UILabel alloc] initWithFrame:CGRectMake(0,0, accuracyLabelLabel.frame.size.width, .5)];
    accuracyLabelLine.backgroundColor = strokeColor;
    [accuracyLabelLabel addSubview:accuracyLabelLine];
    
    
    trialCountLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, screenWidth, labelHeight)];
    trialCountLabel.center=CGPointMake(screenWidth*.5, screenHeight+labelOffset+25);
    trialCountLabel.text=@"0";
    trialCountLabel.textAlignment = NSTextAlignmentCenter;
    trialCountLabel.backgroundColor = [UIColor clearColor];
    trialCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:39];
    trialCountLabel.textColor=strokeColor;
    trialCountLabel.alpha=0;
    [scrollView addSubview:trialCountLabel];
    
    UILabel* trialCountLabelLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0, 100, 40)];
    trialCountLabelLabel.center=CGPointMake(trialCountLabel.frame.size.width/2.0, trialCountLabel.frame.size.height/2.0+labelHeight*.5);
    trialCountLabelLabel.text=@"TRIALS";
    trialCountLabelLabel.textAlignment = NSTextAlignmentCenter;
    trialCountLabelLabel.backgroundColor = [UIColor clearColor];
    trialCountLabelLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    trialCountLabelLabel.textColor=strokeColor;
    trialCountLabelLabel.alpha=1;
    [trialCountLabelLabel setUserInteractionEnabled:NO];
    [trialCountLabel addSubview:trialCountLabelLabel];
    
    UILabel* trialCountLabelLine=[[UILabel alloc] initWithFrame:CGRectMake(0,0, trialCountLabelLabel.frame.size.width, .5)];
    trialCountLabelLine.backgroundColor = strokeColor;
    [trialCountLabelLabel addSubview:trialCountLabelLine];
    
    
    
    
    
    
    
#pragma mark - Buttons

    showScoreboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [showScoreboardButton addTarget:self
                         action:@selector(showScoreboard)
               forControlEvents:UIControlEventTouchUpInside];
    
    showScoreboardButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:24];
    [showScoreboardButton setTitle:@"▾\U0000FE0E" forState:UIControlStateNormal];
    [showScoreboardButton setTitleColor:fgColor forState:UIControlStateNormal];
    showScoreboardButton.frame = CGRectMake(0,0, 88.0, 88.0);
    showScoreboardButton.center=CGPointMake(screenWidth*.5, screenHeight+88);
    [scrollView addSubview:showScoreboardButton];
    

    gameCenterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [gameCenterButton addTarget:self
               action:@selector(showGlobalLeaderboard)
     forControlEvents:UIControlEventTouchUpInside];
    
    [gameCenterButton setImage:[UIImage imageNamed:@"leaderboard"] forState:UIControlStateNormal];

    [gameCenterButton setTitleColor:fgColor forState:UIControlStateNormal];
    gameCenterButton.frame = CGRectMake(screenWidth*.5-44-60, screenHeight*1.5-88, 88.0, 88.0);
    float inset=33.0f;
    [gameCenterButton setImageEdgeInsets:UIEdgeInsetsMake(inset,inset,inset,inset)];
    [scrollView addSubview:gameCenterButton];

    //[self updateHighscore];
    
    
    infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [infoButton addTarget:self
                         action:@selector(showIntroView)
               forControlEvents:UIControlEventTouchUpInside];
    
    [infoButton setImage:[[UIImage imageNamed:@"infoicon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [infoButton setTitleColor:fgColor forState:UIControlStateNormal];
    infoButton.frame = CGRectMake(screenWidth*.5-44+60, screenHeight*1.5-88, 88.0, 88.0);
    [infoButton setImageEdgeInsets:UIEdgeInsetsMake(inset,inset,inset,inset)];

    infoButton.tintColor=fgColor;

    [scrollView addSubview:infoButton];

    
    
    
    
#pragma mark - Mid Marks
    int markWidth=20;
    int markHeight=5;
    int courtWidth=320;
    

    midMarkLine=[[UIView alloc] initWithFrame:CGRectMake(screenWidth*.5-courtWidth*.5, screenHeight*.5, courtWidth, 2)];
    midMarkLine.backgroundColor=strokeColor;
    midMarkLine.alpha=dimAlpha;
    [self.view addSubview:midMarkLine];
    
    
    midMarkL=[[UIView alloc] initWithFrame:CGRectMake(screenWidth*.5-courtWidth*.5, screenHeight*.5, markWidth, markHeight)];
    midMarkL.backgroundColor=strokeColor;
    [self.view addSubview:midMarkL];
    
    midMarkR=[[UIView alloc] initWithFrame:CGRectMake(screenWidth*.5+courtWidth*.5-markWidth, screenHeight*.5, markWidth, markHeight)];
    midMarkR.backgroundColor=strokeColor;
    [self.view addSubview:midMarkR];
    
    midMarkL.alpha=dimAlpha;
    midMarkR.alpha=dimAlpha;
    
    
    midMarkLabel=[[UICountingLabel alloc] initWithFrame:CGRectMake(0, -25, 100, 20)];
    midMarkLabel.text=@"50%";
    midMarkLabel.format = @"%.0f%%";
    midMarkLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:15];
    midMarkLabel.alpha=0;
    midMarkLabel.textColor=strokeColor;
    midMarkLabel.method = UILabelCountingMethodLinear;

    //[midMarkL addSubview:midMarkLabel];
    
    
#pragma mark - survey


    
//    screener=[[Screener alloc] initWithFrame:CGRectMake(0, screenHeight*1.5, screenWidth, 1000)];
//    screener.backgroundColor=[UIColor clearColor];
//    screener.alpha=0;
//    [scrollView addSubview:screener];
//    
//    
    
    surveyView=[[SurveyView alloc] initWithFrame:CGRectMake(0, screenHeight*1.5, screenWidth, surveyHeight)];
    surveyView.backgroundColor=[UIColor clearColor];
    surveyView.alpha=0;
    [scrollView addSubview:surveyView];
    

#pragma mark - intro
    intro=[[UIView alloc] initWithFrame:CGRectMake(0, screenHeight*1.5, screenWidth, introHeight)];
    intro.backgroundColor=bgColor;
    intro.userInteractionEnabled=NO;
    //intro.backgroundColor=[UIColor clearColor];
    [scrollView addSubview:intro];
    
    int m=10;
    //int w=screenWidth-m*2.0;
    int w=280;
    //instructions
    
    
    introTitle=[[UILabel alloc] initWithFrame:CGRectMake(m, m*3, w, 35)];
    introTitle.center=CGPointMake(screenWidth*.5, introTitle.center.y);
    introTitle.font = [UIFont fontWithName:@"DIN Condensed" size:31];
    //introTitle.adjustsFontSizeToFitWidth=YES;
    introTitle.textAlignment=NSTextAlignmentCenter;
    introTitle.text=@"BOOST YOUR BRAIN SENSORS";
    introTitle.textColor=strokeColor;
    [intro addSubview:introTitle];
    
    
    //    introSubtitle=[[UILabel alloc] initWithFrame:CGRectMake(m, 15, w, 90)];
    //    introSubtitle.font = [UIFont fontWithName:@"DIN Condensed" size:32];
    //    introSubtitle.numberOfLines=3;
    //    introSubtitle.text=@"TEST";
    //    introSubtitle.textColor=strokeColor;
    //    [intro addSubview:introSubtitle];
    
    
    NSMutableParagraphStyle *paragraphStyles = [[NSMutableParagraphStyle alloc] init];
    paragraphStyles.alignment                = NSTextAlignmentLeft;
    paragraphStyles.firstLineHeadIndent      = 0.05;    // Very IMP
    
    introParagraph=[[UILabel alloc] initWithFrame:CGRectMake(m, m*3, w, 700)];
    introParagraph.center=CGPointMake(screenWidth*.5, introParagraph.center.y);
    introParagraph.font = [UIFont fontWithName:@"DIN Condensed" size:18];
    introParagraph.numberOfLines=35;
    introParagraph.textColor=strokeColor;
    
    NSString *stringTojustify                = @"Cristiano Ronaldo can famously volley a corner kick in total darkness. The magic behind this remarkable feat is hidden in Cristiano’s brain which enables him to use advance cues to plan upcoming actions. Darkball challenges your brain to do the same, distilling that scenario into its simplest form - intercept a ball in the dark. All you see is all you need.\n\nOne of the brain’s fundamental functions is to use information from the past and present to predict the future. This function is key to how animals, from dragonflies to humans, navigate a dynamic and uncertain world. To make predictions, the brain must have an “internal model” of the system it interacts with. A basic form of this function is at play when we move our body. For example, to reach for a cup, the brain must have a model to predict how the hand will respond to various motor commands. Internal models are also thought to play a crucial role when we mentally predict future states of the environment, for example when we track a ball as it moves behind another object. Here, we have designed a simple task to understand how the nervous system makes such predictions. In this task, subjects have to intercept a ball when it reaches its final position. By changing the speed of the ball, the intervals when it is invisible, and the target position, we will test various hypotheses about the algorithms that are used to integrate information about past and present to make predictions about the future.";
    NSDictionary *attributes                 = @{NSParagraphStyleAttributeName: paragraphStyles};
    NSAttributedString *attributedString     = [[NSAttributedString alloc] initWithString:stringTojustify attributes:attributes];
    
    introParagraph.attributedText             = attributedString;
    intro.alpha=1;
    [intro addSubview:introParagraph];
    

    
//    credits=[[UILabel alloc] initWithFrame:CGRectMake(m, screenHeight-55, w, 40)];
//    credits.font = [UIFont fontWithName:@"HelveticaNeue" size:9];
//    credits.numberOfLines=3;
//    credits.textAlignment=NSTextAlignmentCenter;
//    credits.text=@"TATATA";
//    //credits.textColor=[self getForegroundColor:0];
//    [intro addSubview:credits];
//    
    
//    UITapGestureRecognizer *tapGestureRecognizer3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPressed)];
//    tapGestureRecognizer3.numberOfTouchesRequired = 1;
//    tapGestureRecognizer3.numberOfTapsRequired = 1;
//    [self.view addGestureRecognizer:tapGestureRecognizer3];
//    self.view.userInteractionEnabled=YES;
    
    
    
    if([defaults objectForKey:@"flashDuration"] == nil){
        flashDuration=0.08;
        [defaults setObject:[NSNumber numberWithFloat:flashDuration] forKey:@"flashDuration"];
    }
    else flashDuration = (float)[defaults floatForKey:@"flashDuration"];

    if([defaults objectForKey:@"accuracyStart"] == nil) {
        accuracyStart=0.25;
        [defaults setObject:[NSNumber numberWithFloat:accuracyStart] forKey:@"accuracyStart"];

    }
    else accuracyStart = (float)[defaults floatForKey:@"accuracyStart"];

    if([defaults objectForKey:@"accuracyMax"] == nil){
        accuracyMax=0.05;
        [defaults setObject:[NSNumber numberWithFloat:accuracyMax] forKey:@"accuracyMax"];
    }
    else accuracyMax = (float)[defaults floatForKey:@"accuracyMax"];

    if([defaults objectForKey:@"accuracyIncrement"] == nil){
        accuracyIncrement=0.01;
        [defaults setObject:[NSNumber numberWithFloat:accuracyIncrement] forKey:@"accuracyIncrement"];
    }
    else accuracyIncrement = (float)[defaults floatForKey:@"accuracyIncrement"];
    
    if([defaults objectForKey:@"nTrialsInStage"] == nil){
        nTrialsInStage=5.0;
        [defaults setObject:[NSNumber numberWithFloat:nTrialsInStage] forKey:@"nTrialsInStage"];
    }
    else nTrialsInStage = (float)[defaults floatForKey:@"nTrialsInStage"];
    
//    if([defaults objectForKey:@"ballDiameter"] == nil) ballDiameter=80;
//    else ballDiameter = (int)[defaults integerForKey:@"ballDiameter"];
    
    trialCount=[defaults integerForKey:@"trialsPlayed"];
    trialCountLabel.text=[NSString stringWithFormat:@"%li",trialCount];
    accuracyLabel.text=[NSString stringWithFormat:@"%.2f%%",[defaults floatForKey:@"accuracyScore"]*100.0];

    //currentLevel=11;
    //[self restart];
    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
}

- (void) update {
    currentFrameTimestamp= [displayLink timestamp];
    //NSLog(@"frameTimestamp %f", currentFrameTimestamp);
    //NSLog(@"currentTime    %f", CACurrentMediaTime());
    
    frameCount = frameCount + round((currentFrameTimestamp-lastFrameTimestamp)/(1/60.0));
    
    frameOffset+=(currentFrameTimestamp-lastFrameTimestamp)-(1/60.0);

    lastFrameTimestamp = currentFrameTimestamp;

    
    //test flash
//    for( int i=0; i<6 ; i++){
//    [UIView animateWithDuration:0.005
//                          delay:i*.01
//                        options:UIViewAnimationOptionCurveLinear
//                     animations:^{
//                         testBall.alpha=testBall.alpha+.01;
//                         if(testBall.alpha>.3)testBall.alpha=0;
//                         testBall.center=CGPointMake(testBall.center.x, testBall.center.y+.1);
//                         
//                         if(testBall.center.y>screenHeight)testBall.center=CGPointMake(testBall.center.x, 0);
//                         testBall.label.text=[NSString stringWithFormat:@"%i",frameCount];
//                         
//                         scoreGraph.alpha=testBall.alpha;
//                         catchZone.alpha=testBall.alpha/2;
//                         scoreLabel.alpha=testBall.alpha*.33;
//                         
//                     }
//                     completion:^(BOOL finished){
//
//                     }];
//    }
    
    if(dropBall){
        float ballDim=.8;

        [self updateBall];
        [ball setNeedsDisplay];
        
        if(frameCount==1){
            
            //first flash
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                trueD1Duration=currentFrameTimestamp;
                [aTimer start];
                CATransactionDelay=CACurrentMediaTime()-currentFrameTimestamp;
                
                //NSLog(@"frameTimestamp %f", currentFrameTimestamp);
                //NSLog(@"currentTime    %f", aTimer.elapsedSeconds);
                
                ball.alpha=1.0f;
            }];
            CABasicAnimation *startFlash = [CABasicAnimation animationWithKeyPath:@"opacity"];
            
            [startFlash setDuration:.00001];
            [startFlash setFromValue:[NSNumber numberWithFloat:(currentLevel>0)?0.0f:ballDim]];
            [startFlash setToValue:[NSNumber numberWithFloat:1.0f]];
            [startFlash setBeginTime:currentFrameTimestamp];
            
            [ball.layer addAnimation:startFlash forKey:@"startFlash"];
            [CATransaction commit];
            
            
            //first flash off
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                
                if(currentLevel==0 && [[NSUserDefaults standardUserDefaults] boolForKey:@"showExample"])
                {
                    ball.alpha=ballDim;
                    trialSequence=-2;
                    [self updateBall];
                }
                else
                {
                    //[self performSelector:@selector(updateBall) withObject:self afterDelay:timerGoal];
                    ball.alpha=0;
                    ball.center=CGPointMake(screenWidth*.5, startY+(endY-startY)*flashT);
                }
                

                //        float msOff=[aTimer elapsedSeconds];
                //        NSLog(@"startFlash accuracy: %f sec",msOff);
                //if(currentLevel>0)
                
            }];
            
            CABasicAnimation *startFlashOff = [CABasicAnimation animationWithKeyPath:@"opacity"];
            [startFlashOff setDuration:.00001];
            [startFlashOff setFromValue:[NSNumber numberWithFloat:1.0f]];
            [startFlashOff setToValue:[NSNumber numberWithFloat:(currentLevel>0)?0.0f:ballDim]];
            [startFlashOff setBeginTime:currentFrameTimestamp+flashDuration];
            
            [ball.layer addAnimation:startFlashOff forKey:@"startFlashOff"];
            [CATransaction commit];
            
            secondFlash=false;
            
        }
        
        else if(frameCount>=d1Frames+1 && secondFlash==false)
        {
            secondFlash=true;

            //second flash
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                //        trueD1Duration=frameTimestamp-trueD1Duration;
                //        NSLog(@"frameTimestamp diff %f", trueD1Duration);

                //skippedFrames=frameCount-d1Frames-1;
                trueD1Duration=[aTimer elapsedSeconds];
                
                
                droppedFrames=round(frameOffset/(1/60.0));
                //NSLog(@"droppedFrames   %i", droppedFrames );
                frameOffset=0;
    
                    
                //        NSLog(@"aTimer         diff %f", trueD1Duration);
                
                ball.alpha=1.0f;
                midMarkLine.alpha=1.0f;
            }];
            CABasicAnimation *midFlash = [CABasicAnimation animationWithKeyPath:@"opacity"];
            [midFlash setDuration:.00001];
            [midFlash setFromValue:[NSNumber numberWithFloat:(currentLevel>0)?0.0f:ballDim]];
            [midFlash setToValue:[NSNumber numberWithFloat:1.0f]];
            [midFlash setBeginTime:currentFrameTimestamp];
            
            [ball.layer addAnimation:midFlash forKey:@"midFlash"];
            [midMarkLine.layer addAnimation:midFlash forKey:@"midFlash"];
            [CATransaction commit];
            
            //second flashOff
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                
                //actualD2Duration=actualD1Duration/[currentTrial[@"d1"] floatValue]*[currentTrial[@"d2"] floatValue] ;
                //trueTimerGoal=actualD1Duration+actualD2Duration;
                
                //NSLog(@"%f,%f = %f : %f",actualD1Duration, actualD2Duration,trueTimerGoal, timerGoal);
                
                //NSLog(@"D1 Duration: %f : %f sec",actualD1Duration, flashDelay);
                if(currentLevel==0 && [[NSUserDefaults standardUserDefaults] boolForKey:@"showExample"]){
                    ball.alpha=ballDim;
                    midMarkLine.alpha=dimAlpha;
                }
                else {
                    ball.alpha=0;
                    midMarkLine.alpha=0;
                }
                trialSequence=1;
            }];
            CABasicAnimation *midFlashOff = [CABasicAnimation animationWithKeyPath:@"opacity"];
            [midFlashOff setDuration:.00001];
            [midFlashOff setFromValue:[NSNumber numberWithFloat:1.0f]];
            [midFlashOff setToValue:[NSNumber numberWithFloat:(currentLevel>0)?0.0f:ballDim]];
            [midFlashOff setBeginTime:currentFrameTimestamp+flashDuration];
            
            [ball.layer addAnimation:midFlashOff forKey:@"midFlashOff"];
            [midMarkLine.layer addAnimation:midFlashOff forKey:@"midFlashOff"];
            
            [CATransaction commit];
        }
    }
    

    
}

#pragma mark - touch

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {


    if(trialSequence>0)[self buttonPressed];
    
    touchStartTime=[aTimer elapsedSeconds];

    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    //NSLog(@"Touch x : %f y : %f", touchPoint.x, touchPoint.y);
    touchX=touchPoint.x;
    touchY=touchPoint.y;
    
    
    
    
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    touchLength=[aTimer elapsedSeconds]-touchStartTime;
    if(touched){
        touched=NO;
        [self trialStopped];
    }

    

}

- (void)scrollViewDidScroll:(UIScrollView *)_scrollView{
 
    //ignore flicks
    if(trialSequence==0){
        catchZone.center=CGPointMake(catchZone.center.x, -scrollView.contentOffset.y+screenHeight*.5);
        //crosshair.center=CGPointMake(catchZone.frame.size.width*.5, catchZone.frame.size.height*.5);
        //catchZoneButton.center=CGPointMake(catchZone.center.x, -scrollView.contentOffset.y+screenHeight*.5);
        catchZoneButton.center=CGPointMake(screenWidth*.5, screenHeight*.5);

    }
    //arrow
    float d=((screenHeight*.5)-scrollView.contentOffset.y)/(float)(screenHeight*.5);
    showScoreboardButton.alpha=d;
    accuracyLabel.alpha=1.0-d;
    trialCountLabel.alpha=1.0-d;

    //bestLabel.center=CGPointMake(screenWidth*.5, screenHeight*.5+110);

   float startPos=screenHeight*.5+110;
   float endPos=screenHeight-110-47.5-startPos;
   bestLabel.center=CGPointMake(screenWidth*.5, startPos+(endPos)*(1.0-d));
    
    
    [self setIntroPosition];

}

-(void)setIntroPosition{

    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showIntro1"] && loggedIn) {//there is internet!
        surveyView.alpha=1;
        
        
        if([[NSUserDefaults standardUserDefaults]boolForKey:@"showScreening"]){
            [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, screeningHeight+screenHeight*1.5)];
            //intro.frame=CGRectMake(0, surveyHeight+screenHeight*1.5, screenWidth, screenHeight);
            intro.alpha=0;
        }
        else if([[NSUserDefaults standardUserDefaults]boolForKey:@"showQuestionnaire"]){
            [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, questionnaireHeight+screenHeight*1.5)];
            //intro.frame=CGRectMake(0, surveyHeight+screenHeight*1.5, screenWidth, screenHeight);
            intro.alpha=0;
        }
        else if([[NSUserDefaults standardUserDefaults]boolForKey:@"showConsent"]){
            [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, surveyHeight+screenHeight*1.5)];
            //intro.frame=CGRectMake(0, surveyHeight+screenHeight*1.5, screenWidth, screenHeight);
            intro.alpha=0;
        }
        
        //completed entire survey
        else{
            [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, screenHeight*1.5+surveyHeight)];
            //intro.frame=CGRectMake(0, screenHeight*1.5, screenWidth, introHeight);
            intro.alpha=1;
        }
    }
    else{
        surveyView.alpha=0;
        [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, screenHeight*1.5+introHeight)];
        //intro.frame=CGRectMake(0, screenHeight*1.5, screenWidth, introHeight);
        intro.alpha=1;
        
    }
    
}


-(int) getCurrentPage{
    float y=scrollView.contentOffset.y;
    float offset=screenHeight*.33;
    
    if (y>=0 && y< screenHeight*.5-offset) _currentPage = 0;
    else  if (y>=screenHeight*.5-offset && y < screenHeight*1.5-offset) _currentPage = 1;
    else  if (y>=screenHeight*1.5-offset && y < screenHeight*1.5+screeningHeight+200-offset) _currentPage = 2;
    else  if (y>=screenHeight*1.5+screeningHeight-offset && y < screenHeight*1.5+questionnaireHeight+150-offset) _currentPage = 3;
    else _currentPage=3+(y-screenHeight*1.5+questionnaireHeight+200-offset)/screenHeight;
    return _currentPage;
    
}

-(CGFloat) getPageHeight:(int) _page{
    CGFloat pageHeight;
    if(_page==0)pageHeight= 0;
    else if(_page==1)pageHeight= screenHeight*.5;
    else if(_page==2)pageHeight= screenHeight*1.5;
    else if(_page==3)pageHeight= screenHeight*1.5+screeningHeight+200;
    else if(_page==4)pageHeight= screenHeight*1.5+questionnaireHeight+150;
    else pageHeight=screenHeight*1.5+questionnaireHeight+150+screenHeight*(_page-4);
    return pageHeight;
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)_scrollView withVelocity: (CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{

    int newPage = [self getCurrentPage];
    int maxPages=7;
    if (velocity.y == 0) // slow dragging not lifting finger
    {
        //newPage = floor((targetContentOffset->y - [self getPageHeight:_currentPage]/2.0 ) / [self getPageHeight:_currentPage]) + 1;
        newPage = [self getCurrentPage];
       if(newPage>1) return;
    }
    else
    {
        
        newPage = velocity.y > 0 ? _currentPage + 1 : _currentPage - 1;
        
        if (newPage < 0) newPage = 0;
        if (newPage > maxPages) newPage = maxPages;
    }
    
    
    //NSLog(@"Dragging - You will be on %i page (from page %i)", newPage, _currentPage);
    
    *targetContentOffset = CGPointMake( targetContentOffset->x, [self getPageHeight:newPage]);
    

}




#pragma mark - restart

-(void) restart{
    trialSequence=-1;
    [self performSelector:@selector(showStartScreen) withObject:self afterDelay:0.8];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"showScreening"] && _currentUser[@"screened"]==nil ){
        [self performSelector:@selector(showIntroView) withObject:self afterDelay:2.5];
    }
}

-(void)showStartScreen{
    currentLevel=0;


    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         //catchZone.alpha=0;
                         catchZoneCenter.alpha=0;
                         crosshair.alpha=0;

                         [scrollView setContentOffset:CGPointMake(0, 0)];

                         ball.alpha=0;
                         ballAnnotation.alpha=0;
                         dimension.alpha=0;
                         
                         midMarkL.alpha=dimAlpha;
                         midMarkR.alpha=dimAlpha;
                         arc.alpha=dimAlpha;
                     }
                     completion:^(BOOL finished){
                         [catchZone setFill:YES];
                         [catchZone setColor:fgColor];


                         
                         [UIView animateWithDuration:0.4
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveLinear
                                          animations:^{
                                              [self setCatchZoneDiameter];

                                              catchZone.alpha=1;
                                              catchZone.center=CGPointMake(screenWidth*.5,screenHeight*.5);
                                              catchZoneCenter.center=catchZone.center;
                                              catchZoneButton.center=catchZone.center;
                                              crosshair.frame=catchZone.frame;
                                              crosshair.center=CGPointMake(catchZone.frame.size.width*.5, catchZone.frame.size.height*.5);

                                              showScoreboardButton.center=CGPointMake(screenWidth*.5, screenHeight-44);

                                          }
                                          completion:^(BOOL finished){
                                              [self showLabels:YES];

                                              //[self animateLevelReset];
                                              trialSequence=0;
                                              

                                          }];
                     }];

    
}



-(void)updateHighscore{
    bestLabel.text=[NSString stringWithFormat:@"%i",best];
    scoreLabel.text=[NSString stringWithFormat:@"%i",lastScore];

    
}


#pragma mark - Action



//volume buttons
-(void)buttonPressed{

    if(trialSequence<0)return;

    
    //dismiss intro view
//    if(scrollView.contentOffset.y>=screenHeight*.5){
//        [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
//        if([[NSUserDefaults standardUserDefaults] boolForKey:@"showIntro1"]){
//            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showIntro1"];
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showScreening"];
//            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showQuestionnaire"];
//            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showConsent"];
//
//            [[NSUserDefaults standardUserDefaults] synchronize];
//            
//        }
//        return;
//    }
    
    
    //START
    if(trialSequence==0){
        touched=NO;
        trialSequence=-1;
        [self showLabels:NO];
        
        if(currentLevel==0) [self hideStartScreen];
        else [self startTrialSequence];
        
    }
    //STOP
    else if(trialSequence==1){
        touched=YES;
        [self stop];
    }
    

    
}

-(void)hideStartScreen{
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"showIntro1"]){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showIntro1"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showScreening"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showQuestionnaire"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showConsent"];
        [[NSUserDefaults standardUserDefaults] synchronize];
//        NSLog(@"hide screen and dimsiss intro");        
    }

    currentLevel=0;
    shouldAutoStart=false;
    [self animateLevelReset];

    if([[NSUserDefaults standardUserDefaults] boolForKey:@"showExample"]==NO && currentLevel==0)currentLevel=1;
    [self setLevel:currentLevel];

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self setCatchZoneDiameter];
                     }
                     completion:^(BOOL finished){
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             //catchZone.alpha=0;
                             catchZoneCenter.alpha=0;
                             crosshair.alpha=0;
                             showScoreboardButton.center=CGPointMake(screenWidth*.5, screenHeight+88);

                         }
                         completion:^(BOOL finished){
                             //[catchZone setFill:NO];
                             [catchZone setColor:fgColor];
                             trialSequence=-1;
                             
                             
                             [UIView animateWithDuration:0.1
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveEaseOut
                                              animations:^{
                                                  //catchZone.alpha=.5;
                                                  catchZoneCenter.alpha=1;
                                              }
                                              completion:^(BOOL finished){
                                                  [UIView animateWithDuration:0.1
                                                                        delay:0.0
                                                                      options:UIViewAnimationOptionCurveEaseOut
                                                                   animations:^{
                                                                       [catchZone bringSubviewToFront:crosshair];
                                                                       crosshair.alpha=.3;
                                                                       midMarkL.alpha=.3;
                                                                       midMarkR.alpha=.3;
                                                                   }
                                                                   completion:^(BOOL finished){
                                                                       [UIView animateWithDuration:0.1
                                                                                             delay:0.0
                                                                                           options:UIViewAnimationOptionCurveEaseOut
                                                                                        animations:^{
                                                                                            arc.alpha=.3;
                                                                                            [self setCatchZoneDiameter];//in case catchzone is in wrong place

                                                                                        }
                                                                                        completion:^(BOOL finished){
                                                                                            trialSequence=-1;
                                                                                            lastScore=0;

                                                                                            //reset scoreboard
                                                                                            [self updateHighscore];
                                                                                            [self startTrialSequence];
                                                                                        }];
                                                                   }];
                                              }];
                         }];
                }];
}


-(void)stop{
    elapsed=[aTimer elapsedSeconds];
    trialSequence=-1;
    
    trueD2Duration=elapsed-trueD1Duration;//-.06;
    
    
    if([self isAccurate]){
        if([self getAccuracyFloat]<.8) [ball setColor:[UIColor colorWithRed:0 green:.78 blue:0 alpha:1]];//green
        else [ball setColor:[UIColor yellowColor]];
        [ball setNeedsDisplay];
        

        currentScoreLabel.text=[NSString stringWithFormat:@"%i",currentLevel];
        
        if(currentLevel>0){
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 currentScoreLabel.alpha=1;
                             }
                             completion:^(BOOL finished){
                                 
                             }];

        }
        
    }
    //fail
    else{
        [ball setColor:[UIColor redColor]];
        [ball setNeedsDisplay];
        
//#ifdef TESTING
//        
//#else
        //flash background
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.view.backgroundColor=flashColor;
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:0.3
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveLinear
                                              animations:^{
                                                  self.view.backgroundColor=bgColor;
                                              }
                                              completion:^(BOOL finished){
                                                  
                                              }];
                         }];
        
//#endif
        
        //hide example trial
        if(currentLevel>3){
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:NO forKey:@"showExample"];
            [defaults synchronize];
        }
        
        //turn on teaching
        else if(currentLevel<=1){
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"showExample"];
            [defaults synchronize];
        }
        
    }
    
    
//#ifdef TESTING
//    //always no teaching
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:NO forKey:@"showExample"];
//    [defaults synchronize];
//
//#endif


    
    
    [self positionBall:NO];
    ball.alpha=ballAlpha;
    
    
    
    dimension.ballPosition=ball.center;
    dimension.dimLineOffsetX=catchZone.frame.size.width*.5+8;
    dimension.alpha=1;
    [dimension setNeedsDisplay];
    
    float annotationHeight= ballAnnotation.frame.size.height;
    float annotationWidth= ballAnnotation.frame.size.width;
    float midpointToTargetY=endY+(ball.center.y-endY)/2.0;
    
    ballAnnotation.frame=CGRectMake(ball.center.x-annotationWidth-dimension.dimLineOffsetX-15, midpointToTargetY-annotationHeight*.5, annotationWidth, annotationHeight);
    
    float diff=elapsed-timerGoal;
    if(diff<0) ballAnnotation.text=[NSString stringWithFormat:@"%.3fs", diff];
    else ballAnnotation.text=[NSString stringWithFormat:@"+%.3fs", diff];
   
    ballAnnotation.alpha=1;
    

    
    
    
    [self.view.layer removeAllAnimations];
}

-(void)saveTrialData{
    

    
    NSDate* localDateTime = [NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:[NSDate date]];

    
    NSString *configVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"configVersion"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];

    
    //save to disk
    NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
    float diff=trueD2Duration-d2Duration;
    [myDictionary setObject:[NSNumber numberWithFloat:diff] forKey:@"offset"];
    [myDictionary setObject:[NSNumber numberWithFloat:timerGoal] forKey:@"goal"];
    //[myDictionary setObject:[NSNumber numberWithFloat:trueTimerGoal] forKey:@"trueGoal"];

    [myDictionary setObject:[NSNumber numberWithFloat:trialDelay] forKey:@"trialDelay"];
    [myDictionary setObject:[NSNumber numberWithFloat:CATransactionDelay] forKey:@"CATransactionDelay"];
    [myDictionary setObject:[NSNumber numberWithInt:droppedFrames] forKey:@"droppedFrames"];

    [myDictionary setObject:[NSNumber numberWithFloat:flashT] forKey:@"flashT"];
    [myDictionary setObject:[NSNumber numberWithInt:[currentTrial[@"index"]intValue]] forKey:@"trialIndex"];

    [myDictionary setObject:[NSNumber numberWithFloat:[currentTrial[@"d1"]floatValue]] forKey:@"d1"];
    [myDictionary setObject:[NSNumber numberWithFloat:[currentTrial[@"d2"]floatValue]] forKey:@"d2"];
    [myDictionary setObject:[NSNumber numberWithFloat:[currentTrial[@"duration"]floatValue]] forKey:@"duration"];
    [myDictionary setObject:[NSNumber numberWithFloat:levelAccuracy] forKey:@"errorWindow"];

    
    [myDictionary setObject:[NSNumber numberWithInt:d1Frames] forKey:@"d1Frames"];
    [myDictionary setObject:[NSNumber numberWithInt:d2Frames] forKey:@"d2Frames"];

    [myDictionary setObject:[NSNumber numberWithFloat:d1Duration] forKey:@"d1Duration"];
    [myDictionary setObject:[NSNumber numberWithFloat:d2Duration] forKey:@"d2Duration"];
    [myDictionary setObject:[NSNumber numberWithFloat:trueD1Duration] forKey:@"trueD1Duration"];
    [myDictionary setObject:[NSNumber numberWithFloat:trueD2Duration-.06] forKey:@"trueD2Duration"];
    [myDictionary setObject:[NSNumber numberWithInteger:currentLevel] forKey:@"level"];
    [myDictionary setObject:[NSNumber numberWithBool:([self isAccurate])? YES:NO] forKey:@"win"];
    [myDictionary setObject:localDateTime forKey:@"date"];
    [myDictionary setObject:[NSTimeZone localTimeZone].abbreviation forKey:@"timezone"];
    //[myDictionary setObject:[NSNumber numberWithBool: (touched)? YES:NO ] forKey:@"didTouch"];
    //if(touched){
    [myDictionary setObject:[NSNumber numberWithFloat: touchX ] forKey:@"touchX"];
    [myDictionary setObject:[NSNumber numberWithFloat: touchY ] forKey:@"touchY"];
    [myDictionary setObject:[NSNumber numberWithFloat: touchLength ] forKey:@"touchLength"];
    [myDictionary setObject:[NSNumber numberWithFloat: trueD1Duration ] forKey:@"actualD1Duration"];
    [myDictionary setObject:build forKey:@"build"];

    

    
    
    if(configVersion!=nil)[myDictionary setObject:configVersion forKey:@"configVersion"];

    //}
    [self.allTrialData addObject:myDictionary];
    [self.allTrialData writeToFile:allTrialDataFile atomically:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    //save research record locally (was Parse "results")
    if([_currentUser[@"iAgree"] boolValue]){
        NSMutableDictionary *record = [myDictionary mutableCopy];

        NSString*uuid;
        if([defaults stringForKey:@"uuid"] == nil){
            uuid=[[NSUUID UUID] UUIDString];
            [defaults setObject:uuid forKey:@"uuid"];
        }
        else uuid =[defaults stringForKey:@"uuid"];
        record[@"uuid"]=uuid;
        record[@"errorWindow"]=[NSNumber numberWithFloat:levelAccuracy];
        record[@"trialDelay"]=[NSNumber numberWithFloat:trialDelay];

        [[TrialStore shared] appendTrial:record];
    }

    //[_currentUser incrementKey:@"trialsPlayed"];
    trialCount++;
    trialCountLabel.text=[NSString stringWithFormat:@"%li",trialCount];
    [defaults setObject:[NSNumber numberWithLong:trialCount] forKey:@"trialsPlayed"];
    _currentUser[@"trialsPlayed"]=[NSNumber numberWithLong:trialCount];

    
    _currentUser[@"best"]=[NSNumber numberWithFloat:best];
    
//    float d2Duration=[currentTrial[@"duration"]floatValue]*[currentTrial[@"d2"]floatValue];
//    accuracyScore=(d2Duration-fabs(diff))/(float)d2Duration;
//    accuracyScore=([_currentUser[@"accuracyScore"] floatValue]+accuracyScore)/2.0;

    
//    _currentUser[@"accuracyScore"]=[NSNumber numberWithFloat:accuracyScore];
//    accuracyLabel.text=[NSString stringWithFormat:@"%.3f%%",accuracyScore*100.0];
//    [defaults setObject:[NSNumber numberWithFloat:[_currentUser[@"accuracyScore"] floatValue] ] forKey:@"accuracyScore"];
    
    float accuracy;
    //if(elapsed<=timerGoal) accuracy=(float)elapsed/(float)timerGoal;
    //else accuracy=1.0-fabs(elapsed-timerGoal)/(float)timerGoal;

    if(elapsed<=timerGoal) accuracy=(float)trueD2Duration/(float)d2Duration;
    else accuracy=1.0-fabs(trueD2Duration-d2Duration)/(float)d2Duration;
    
    //NSLog(@"accuracy %f",accuracy);
    
    if(accuracy>.5){
        [accuracyHistory  addObject:[NSNumber numberWithFloat:accuracy]];
        [accuracyHistory writeToFile:accuracyHistoryDataFile atomically:YES];
        scoreGraph.accuracyScore=accuracyHistory;
        
        [defaults setObject:[NSNumber numberWithFloat:[scoreGraph getAccuracyAverage]] forKey:@"accuracyScore"];
        [defaults synchronize];
    }
    accuracyLabel.text=[NSString stringWithFormat:@"%.2f%%",[defaults floatForKey:@"accuracyScore"]*100.0];


    [_currentUser saveEventually];
    
 
    
    
}


-(void)showIntroView{
    [scrollView setContentOffset:CGPointMake(0, screenHeight*1.5) animated:YES];
}

-(void)showQuestionnaire{
 [scrollView setContentOffset:CGPointMake(0, screenHeight*1.5+950) animated:YES];
}

#pragma mark DATA
-(void)loadTrialData{
    
    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    self.allTrialData = [[NSMutableArray alloc] init];
    allTrialDataFile = [[docPath objectAtIndex:0] stringByAppendingPathComponent:@"allTrialData.dat"];
    self.allTrialData = [[NSMutableArray alloc] initWithContentsOfFile: allTrialDataFile];
    if(self.allTrialData == nil){
        
        self.allTrialData = [[NSMutableArray alloc] init];
        //for (int i = 0; i <1 ; i++) {
        NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
        [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"accuracy"];
        [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"goal"];
        [myDictionary setObject:[NSDate date] forKey:@"date"];
        [myDictionary setObject:[NSNumber numberWithFloat:0.0] forKey:@"flashT"];

        [self.allTrialData addObject:myDictionary];
    
        [self.allTrialData writeToFile:allTrialDataFile atomically:YES];
    }
    
    NSArray *libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    scoreHistory = [[NSMutableArray alloc] init];
    scoreHistoryDataFile = [[libPath objectAtIndex:0] stringByAppendingPathComponent:@"scoreHistory.dat"];
    scoreHistory = [[NSMutableArray alloc] initWithContentsOfFile: scoreHistoryDataFile];
    if(scoreHistory == nil){
        
        scoreHistory = [[NSMutableArray alloc] init];
        [scoreHistory addObject:[NSNumber numberWithInteger:0]];
        [scoreHistory writeToFile:scoreHistoryDataFile atomically:YES];
    }
    
    scoreGraph.yValues=scoreHistory;
    
    
    accuracyHistory = [[NSMutableArray alloc] init];
    accuracyHistoryDataFile = [[libPath objectAtIndex:0] stringByAppendingPathComponent:@"accuracyHistory"];
    accuracyHistory = [[NSMutableArray alloc] initWithContentsOfFile: accuracyHistoryDataFile];
    if(accuracyHistory == nil){
        accuracyHistory = [[NSMutableArray alloc] init];
        [accuracyHistory addObject:[NSNumber numberWithFloat:0]];
        [accuracyHistory writeToFile:accuracyHistoryDataFile atomically:YES];
    }
    
    scoreGraph.accuracyScore=accuracyHistory;
    
    
    [scoreGraph setNeedsDisplay];
    

}





#pragma mark - GameCenter
-(void)reportScore{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(currentLevel>0){
        if(currentLevel>=best){
            best=currentLevel;
            [defaults setInteger:best forKey:@"best"];
        }
    }
    lastScore=currentLevel;
    [[NSUserDefaults standardUserDefaults] setInteger:lastScore forKey:@"lastScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self updateHighscore];
    [defaults synchronize];
    
    
    if(_leaderboardIdentifier){
        GKScore *score = [[GKScore alloc] initWithLeaderboardIdentifier:@"global.tatata"];
        score.value = best;
        
        [GKScore reportScores:@[score] withCompletionHandler:^(NSError *error) {
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
            }
        }];

  
    }
}

-(void)showScoreboard{
    
    [scrollView setContentOffset:CGPointMake(0, screenHeight*.5) animated:YES];
    
}
-(void)showGlobalLeaderboard{
    GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] init];
    gcViewController.gameCenterDelegate = self;
    gcViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
    gcViewController.leaderboardIdentifier = @"global.tatata";
    [self presentViewController:gcViewController animated:YES completion:nil];
}


-(void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark BALL

-(void)startTrialSequence{

    touchX=0;
    touchY=0;
    touchLength=0;
    //double initDelay=.4;
    //double flashDelay=timerGoal*(float)flashT;
    //int d1Frames=[currentTrial[@"duration"] floatValue] * [currentTrial[@"d1"] floatValue] *60.0;

    //NSLog(@"flashDelay %f",flashDelay);
    //quantize to 1/60
    //int nFrames=flashDelay*60.0;
    //NSLog(@"nFrames %i",nFrames);
    //float flashDelay=d1Frames/60.0;
    //NSLog(@"flashDelay %f",flashDelay);
    
    
    
    //float flashDuration=[config[@"flashDuration"]floatValue];
    
    [ball setColor:strokeColor];
    [ball setNeedsDisplay];
    
    trialDelay =.5+((double)arc4random() / ARC4RANDOM_MAX)*.65;
    float objAlpha=.4;

    //ambient lights
    UIColor *bg=bgColor;
    if( currentLevel==0  && [[NSUserDefaults standardUserDefaults] boolForKey:@"showExample"] ){
        CGFloat hue, saturation, brightness, alpha ;
        BOOL ok = [ bgColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha ] ;
        if ( !ok ) {
            // handle error
        }
        brightness=.4;
        
        bg = [ UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha ] ;
        objAlpha=1.0;
    }
    
    //if(currentLevel<=1)trialDelay=baseDelay;
    //if(currentLevel%(int)(nTrialsInStage)==0 && currentLevel!=0)trialDelay+=1.4;
    
    [UIView animateWithDuration:.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         
                         //dim background
                         self.view.backgroundColor=bg;
                         catchZone.alpha=.5;
                         midMarkL.alpha=objAlpha;
                         midMarkR.alpha=objAlpha;
                         arc.alpha=objAlpha;
                         

                         
                         //hide annotation
                         ballAnnotation.alpha=0;
                         dimension.alpha=0;
                         
                         if(currentLevel==0  && [[NSUserDefaults standardUserDefaults] boolForKey:@"showExample"]){
                             ball.alpha=1.0;
                         }

                     }
                     completion:^(BOOL finished){
                         
                         //set catchzone and show dims
                         [UIView animateWithDuration:0.4
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              if(currentLevel%(int)(nTrialsInStage)==0 && currentLevel!=0)
                                              {
                                                  //catchZoneLabel.alpha=1;
                                                  //catchZone.alpha=1;
                                              }
                                          }
                                          completion:^(BOOL finished){
                                              

                                              float catchZoneDuration=0.0;
                                              
                                              //set for level 0 even though it's not visible
                                              if(currentLevel%(int)(nTrialsInStage)==0 || currentLevel<=1)
                                              {
                                                //[catchZoneLabel countFrom:[self getLevelAccuracy:currentLevel-nTrialsInStage]/timerGoal*200.0  to:[self getLevelAccuracy:currentLevel]/timerGoal*200.0 withDuration:.2f];
                                                    //[catchZoneLabel countFrom:[self getLevelAccuracy:currentLevel-1]/d2Duration*100.0  to:[self getLevelAccuracy:currentLevel]/d2Duration*100.0 withDuration:.2f];
                                                  //catchZoneDuration=.4;

                                              }

                                            [UIView animateWithDuration:catchZoneDuration
                                                                    delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseOut
                                                               animations:^{
                                                                   [self setCatchZoneDiameter];
                                                                   
//                                                                   UIColor *color =  catchZone.dotColor;
//                                                                   CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
//                                                                   if ([color respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
//                                                                       [color getRed:&red green:&green blue:&blue alpha:&alpha];
//                                                                   
//                                                                       catchZone.dotColor=[UIColor colorWithRed:red+currentLevel/2.0 green:green blue:blue alpha:alpha];
//                                                                   }

                                                               }
                                                               completion:^(BOOL finished){
                                                                   [UIView animateWithDuration:0.1
                                                                                         delay:0.2
                                                                                       options:UIViewAnimationOptionCurveEaseOut
                                                                                    animations:^{
                                                                                        catchZoneLabel.alpha=0;
                                                                                        catchZone.alpha=.5;
                                                                                    }
                                                                                    completion:^(BOOL finished){
                                                                                        [UIView animateWithDuration:0.5
                                                                                                              delay:0.0
                                                                                                            options:UIViewAnimationOptionCurveEaseOut
                                                                                                         animations:^{
                                                                                                             if(currentLevel>0){
                                                                                                                 ball.alpha=0;
                                                                                                                 [ball setNeedsDisplay];
                                                                                                            }
                                                                                                         }
                                                                                                         completion:^(BOOL finished){
                                                                                                             [UIView animateWithDuration:0.2
                                                                                                                                   delay:trialDelay
                                                                                                                                 options:UIViewAnimationOptionCurveLinear
                                                                                                                              animations:^{
                                                                                                                                  ball.alpha=0.001;
                                                                                                                              }
                                                                                                                              completion:^(BOOL finished){
                                                                                                                                  //start ball drop
                                                                                                                                  frameCount=0;
                                                                                                                                  droppedFrames=0;
                                                                                                                                  frameOffset=0;
                                                                                                                                  shouldAutoStart=true;
                                                                                                                                  dropBall=true;
                                                                                                                               
                                                                                                                              }];
                                                                                                             
                                                                                                         }];
                                                                                    }];
                                                               }];
                                          }];

                     }];
    

}

-(void)positionBall:(BOOL)animate{
    CGPoint p;
    if(elapsed==0)p=CGPointMake(screenWidth*.5, startY);
    else p=CGPointMake(screenWidth*.5, startY+(float)(endY-startY)*(float)elapsed/(float)timerGoal);
    if(animate){
        [UIView animateWithDuration:0.6
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             ball.center=p;
                         }
                         completion:^(BOOL finished){
                         }];
    }
    else{
        //ball.alpha=1;
        ball.center=p;
    }
    
}


-(float)getLevel:(int)level{
    //userdefault last level
    //float l=[currentTrial[@"d1"] floatValue]+[currentTrial[@"d2"] floatValue];
    //float l=[currentTrial[@"duration"] floatValue] * [currentTrial[@"d2"] floatValue]+[currentTrial[@"duration"] floatValue] * [currentTrial[@"d1"] floatValue];

    d1Frames=[currentTrial[@"duration"] floatValue] * [currentTrial[@"d1"] floatValue] *60.0;
    d1Duration=d1Frames/60.0;
    
    d2Frames=[currentTrial[@"duration"] floatValue] * [currentTrial[@"d2"] floatValue] *60.0;
    d2Duration=d2Frames/60.0;
    

    
    float l=d1Duration+d2Duration;
    return l;
    
    
//    float l;
//
//    if (level==0)l=1.5;
//    else {
//        //l=.7+level*0.1;
//        NSInteger randomNumber = arc4random() % 25;
//        NSInteger coinFlip = arc4random() % 1;
//        
//        if(coinFlip==0)coinFlip=1;
//        else coinFlip=-1;
//
//        l=1.5+level*randomNumber/100.0*coinFlip;
//        
//        if(l<.5)l=.5;
//        
//    }
//    return l;
}

-(float)getFlashT:(int)level{
    //    float f=.5;
    //    NSInteger random = arc4random() % 3;
    //
    //    if (level>=3) f=.5-random*.1;
    //float f=[currentTrial[@"d1"] floatValue]/([currentTrial[@"d1"] floatValue]+[currentTrial[@"d2"] floatValue]);
    
    //float f=[currentTrial[@"d1"] floatValue]/([currentTrial[@"d1"] floatValue]+[currentTrial[@"d2"] floatValue]);
    float f=d1Duration/(d1Duration+d2Duration);

    return f;
}

-(float)getLevelAccuracy:(int)level{
    
    //return .2;
    
    //return timerGoal*.1;
    if(level==0 && [[NSUserDefaults standardUserDefaults] boolForKey:@"showExample"])return d2Duration*accuracyStart;
    
    //int stage=(5+level)/10.0;
    //float accuracy=accuracyStart-accuracyIncrement*level/25.0;
    levelAccuracy=accuracyStart-accuracyIncrement*floor(level/nTrialsInStage)*nTrialsInStage;

    if(levelAccuracy<accuracyMax)levelAccuracy=accuracyMax;
    float levelAccuracyInSeconds=d2Duration*levelAccuracy;
    return levelAccuracyInSeconds;
    
    
}






# pragma mark LABELS
-(void)showLabels:(BOOL) show{
    
    bestLabel.text=[NSString stringWithFormat:@"%i",best];
    scoreLabel.text=[NSString stringWithFormat:@"%i",lastScore];
    
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         if(show){
                             scrollView.alpha=1;


                             if(![bestLabel.text isEqualToString:@"0"]) {
                                 scoreLabel.alpha=1;
                                bestLabel.alpha=1;
                             }
                             else{
                                 scoreLabel.alpha=0;
                                 bestLabel.alpha=0;
                             }
                         }
                         else{
                             scrollView.alpha=0;
                         }
                     }
                     completion:^(BOOL finished){
                         
                     }];
    
    
}


# pragma mark

-(void)updateBall{
    
    if(trialSequence==1 || trialSequence==-2){
//        [self performSelector:@selector(updateBall) withObject:self afterDelay:0.001];

        
        elapsed=[aTimer elapsedSeconds];
        [self positionBall:NO];
        
        if(ball.center.y>=endY+screenHeight*.5){
            [self stop];
            [self trialStopped];
        }
    }

}




-(void)trialStopped{

    //save trial data now
    [self saveTrialData];
    
    if([self isAccurate]){

        [self reportScore];

        currentLevel++;
        [self setLevel:currentLevel];
        [self loadTrialData];
        [self performSelector:@selector(animateLevelReset) withObject:self afterDelay:0.3];
        
    }
    else{
        [scoreHistory  addObject:[NSNumber numberWithInteger:currentLevel]];
        [scoreHistory writeToFile:scoreHistoryDataFile atomically:YES];
        scoreGraph.yValues=scoreHistory;
        
        [scoreGraph setNeedsDisplay];

        [self setLevel:currentLevel];
        [self restart];
    }
    dropBall=false;
    
    
    
}



-(void)setLevel:(int)level{
    //insequence
    //currentTrial=[trialArray objectAtIndex: ([_currentUser[@"trialsPlayed"] integerValue]+level)%[trialArray count]];
    
    //random
    currentTrial=[trialArray objectAtIndex: arc4random()%[trialArray count]];

    timerGoal=[self getLevel:level];
    flashT=[self getFlashT:level];
}



-(void)animateLevelReset{
    elapsed=0;
    //[self positionBall:YES];

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         //set ball position
                         ball.center=CGPointMake(screenWidth*.5, startY);
                         [ball setColor:strokeColor];
                         
                         if(currentLevel>1) ball.alpha=.5;
                         [ball setNeedsDisplay];
                         currentScoreLabel.alpha=0;
                         
//                         if(currentLevel%(int)nTrialsInStage==0 && currentLevel!=0){
//                             catchZoneLabel.alpha=1;
//                             catchZone.alpha=1;
//                         }
                         
                         if(midMarkLine.center.y!=startY+(endY-startY)*flashT){
                             midMarkLabel.alpha=1;
                             midMarkLine.alpha=1;
                             midMarkL.alpha=1;
                             midMarkR.alpha=1;
                             
                         }
                         
                         //[self resetCatchZoneDiameter];

                     }
                     completion:^(BOOL finished){
                         /*
                         if(midMarkLine.center.y!=startY+(endY-startY)*flashT){
                             [midMarkLabel countFrom:0  to:(int)(flashT*100) withDuration:.4f];
                         }
                         */
                                       [UIView animateWithDuration:0.3
                                                             delay:0.0
                                                           options:UIViewAnimationOptionCurveEaseOut
                                                        animations:^{

                                                            catchZoneLabel.alpha=0;
                                                            catchZone.alpha=.5;
                                                            
                                                            //hide annotation
                                                            ballAnnotation.alpha=0;
                                                            dimension.alpha=0;
                                                            
                                                            //set mid markers
                                                            midMarkL.center=CGPointMake(midMarkL.center.x, startY+(endY-startY)*flashT);
                                                            midMarkR.center=CGPointMake(midMarkR.center.x, startY+(endY-startY)*flashT);
                                                            midMarkLine.center=CGPointMake(midMarkLine.center.x, startY+(endY-startY)*flashT);
                                                            
                                                            //adjust catchzone to d2 duration
                                                            //catchZoneLabel.alpha=1;
                                                            //catchZone.alpha=1;

                                                            //if next level isn't a stage up
                                                            //if((currentLevel)%(int)(nTrialsInStage)==0 || (currentLevel)<=1)
                                                            {
                                                                
                                                            }
                                                            //else
                                                            {
                                                                [self setCatchZoneDiameter];

                                                            }

                                                        }
                                                        completion:^(BOOL finished){
                                                            
                                                            [UIView animateWithDuration:0.2
                                                                                  delay:0.4
                                                                                options:UIViewAnimationOptionCurveEaseOut
                                                                             animations:^{
                                                                                 midMarkLabel.alpha=dimAlpha;
                                                                                 midMarkLine.alpha=dimAlpha;
//                                                                                 midMarkL.alpha=dimAlpha;
//                                                                                 midMarkR.alpha=dimAlpha;
                                                                                 //catchZoneLabel.alpha=0;
                                                                                 //catchZone.alpha=0;


                                                                             }
                                                                             completion:^(BOOL finished){
                                                                                 //autostart next level
                                                                                 if(currentLevel>0 && shouldAutoStart){
                                                                                     trialSequence=0;
                                                                                     [self buttonPressed];
                                                                                 }
                                                                                 
                                                                             }];
                                                
                                                            
                                                        }];
                                   }];
                     //}];


}

-(void)setCatchZoneDiameter{
    //float catchZoneDiameter=[self getLevelAccuracy:currentLevel]*(endY-startY)/timerGoal*2.0;

    float d2Pixels=endY-startY-((endY-startY)*flashT);
    
    float catchZoneDiameter=(float)[self getLevelAccuracy:currentLevel]/d2Duration*d2Pixels*2.0f;

    catchZone.frame=CGRectMake(0, 0, catchZoneDiameter, catchZoneDiameter);

 //   if(currentLevel<=1)
    {
        float startZoneDiameter=catchZoneDiameter;
        ball.frame=CGRectMake(0,0, catchZoneDiameter*.75, catchZoneDiameter*.75);
        ball.center=CGPointMake(screenWidth*.5, startY);
        //ball.lineWidth=ball.frame.size.width*.325;
        dotInDot.center=CGPointMake(ball.frame.size.width*.5, ball.frame.size.height*.5);

        arc.frame=CGRectMake(0,0, startZoneDiameter,startZoneDiameter);
        arc.center=ball.center;
        [arc setNeedsDisplay];

    }

    catchZone.center=CGPointMake(screenWidth*.5, endY);
    catchZoneCenter.center=catchZone.center;
    crosshair.frame=catchZone.frame;
    crosshair.center=CGPointMake(catchZone.frame.size.width*.5, catchZone.frame.size.height*.5);

    [catchZone setNeedsDisplay];
    
}


# pragma mark Helpers

-(bool)isAccurate{
    float diff=fabs(trueD2Duration-d2Duration);
    
    //NSLog(@"diff %f:%f ",diff,[self getLevelAccuracy:currentLevel]);
    
    if( diff<=[self getLevelAccuracy:currentLevel] ) return YES;
    else return NO;
}
-(float)getAccuracyFloat{
    float f;
    f=fabs((trueD2Duration-d2Duration))/[self getLevelAccuracy:currentLevel];
    return f;
}

//-(int)getAccuracyPercentage{
//    float accuracyPercent=100.0-fabs(trueTimerGoal-elapsed)/(float)trueTimerGoal*100.0;
//    if(accuracyPercent<0)accuracyPercent=0;
//    return accuracyPercent;
//}


#pragma mark - ViewController Delegate

- (void)viewDidUnload
{

   [super viewDidUnload];
   // Release any retained subviews of the main view.
   // e.g. self.myOutlet = nil;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"view resigned");
}


- (void)viewWillAppear:(BOOL)animated
{
    
    NSLog(@"view will appear");
    loggedIn=false;
    
    [self logIn];
    
    [self getTrialSequence];


    [super viewWillAppear:animated];
}



- (void)viewDidAppear:(BOOL)animated
{
    [self loadTrialData];

    currentLevel=0;
    trialSequence=-1;
    [self setLevel:currentLevel];
    trialSequence=-1;
    [self performSelector:@selector(showStartScreen) withObject:self afterDelay:0.8];

    if([[NSUserDefaults standardUserDefaults] boolForKey:@"showIntro1"] ) [self performSelector:@selector(showIntroView) withObject:self afterDelay:2.5];

    [super viewDidAppear:animated];
}


-(void)getTrialSequence{
    NSArray *libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    trialArrayDataFile=[[libPath objectAtIndex:0] stringByAppendingPathComponent:@"trialSequence.dat"];

    [self loadLocalTrialSequence];
}

-(void)loadLocalTrialSequence{
    
    //load locally
    trialArray = [[NSMutableArray alloc] initWithContentsOfFile: trialArrayDataFile];

    //if local file doesn't exists, make one
    if(trialArray == nil){
        trialArray = [[NSMutableArray alloc] init];
        
        [trialArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:1],@"d1", [NSNumber numberWithFloat:1],@"d2",[NSNumber numberWithFloat:0.6],@"duration",[NSNumber numberWithInt:-1],@"index",  nil]];
        
        [trialArray addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:1],@"d1", [NSNumber numberWithFloat:1.5],@"d2",[NSNumber numberWithFloat:0.6],@"duration",[NSNumber numberWithInt:-1],@"index",  nil]];

        [trialArray writeToFile:trialArrayDataFile atomically:YES];
    
    }
    
    
     
}

-(void)logIn{
    _currentUser = [LocalUser currentUser];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString*uuid;
    if([defaults stringForKey:@"uuid"] == nil){
        uuid=[[NSUUID UUID] UUIDString];
        [defaults setObject:uuid forKey:@"uuid"];
    }
    else uuid =[defaults stringForKey:@"uuid"];
    _currentUser[@"uuid"]=uuid;
    _currentUser[@"deviceName"]=[self deviceName];
    _currentUser[@"best"]=[NSNumber numberWithFloat:best];

    loggedIn=true;
    [self setIntroPosition];
}



- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


-(void)authenticateLocalPlayer{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil) {
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else{
            if ([GKLocalPlayer localPlayer].authenticated) {
                _gameCenterEnabled = YES;
                
                // Get the default leaderboard identifier.
                [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
                    
                    if (error != nil) {
                        NSLog(@"%@", [error localizedDescription]);
                    }
                    else{
                        _leaderboardIdentifier = leaderboardIdentifier;
                    }
                }];
            }
            
            else{
                _gameCenterEnabled = NO;
            }
        }
    };
}

-(NSString*) deviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}


@end
