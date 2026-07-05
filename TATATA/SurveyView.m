//
//  SurveyView.m
//  Darkball
//
//  Created by Che-Wei Wang on 1/15/15.
//
//

#import "SurveyView.h"
#import "ViewController.h"

@implementation SurveyView


- (id)initWithFrame:(CGRect)theFrame {
    self = [super initWithFrame:theFrame];
    if (self) {
        
        self.clipsToBounds=NO;
        

        //ViewController *dele = (ViewController *)[[UIApplication sharedApplication] delegate];
//        float screenHeight=[[UIScreen mainScreen] bounds].size.height;
        float screenWidth=[[UIScreen mainScreen] bounds].size.width;

        currentUser=[LocalUser currentUser];

        UIView *survey = [[[NSBundle mainBundle] loadNibNamed:@"SurveyView" owner:self options:nil] firstObject];
        survey.frame=CGRectMake(0, 0, survey.frame.size.width, survey.frame.size.height);
        survey.center=CGPointMake(screenWidth*.5, survey.center.y);
        //survey.backgroundColor=[UIColor clearColor];
        
        [self addSubview:survey];
        
        [self.sex addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
        [self.handed addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];

    
        NSMutableArray *numArray = [[NSMutableArray alloc] init];
        for(int i=0; i<=120; i++){
            [numArray addObject:[NSString stringWithFormat:@"%i",i]];
        }
        _ages = numArray;

        
        [_agePicker selectRow:0 inComponent:0 animated:NO];
        //change picker selectionline color (guarded: relies on private UIPickerView
        //subview layout that no longer exists on modern iOS)
        if (_agePicker.subviews.count > 1) {
            ((UIView *)[_agePicker.subviews objectAtIndex:1]).backgroundColor = [UIColor grayColor];
        }
        if (_agePicker.subviews.count > 2) {
            ((UIView *)[_agePicker.subviews objectAtIndex:2]).backgroundColor = [UIColor grayColor];
        }
        

//        [_frequentHeadaches addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_dizziness addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_lossOfConsciousness addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_seizures addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_mentalHealth addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//       
//        [_narcotics addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_stimulants addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_cocain addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_lsd addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_marijuana addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
//        [_streetDrugs addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];

        [_professional addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
        [_collegiate addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
        [_amateur addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
        [_intramural addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
        [_casual addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
        [_none addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
 
        [_iAgree addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
        [_iDoNotAgree addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];

        [_yes addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];
        [_no addTarget:self action:@selector(checkboxSelected:) forControlEvents:UIControlEventTouchDown];

        [self loadSurveyResults];
        
        
    }
    return self;
}


-(void)loadSurveyResults{

    [_agePicker selectRow:[currentUser[@"age"] integerValue] inComponent:0 animated:YES];

    int mfIndex;
    if([currentUser[@"sex"] isEqual:@"Male"])mfIndex=0;
    else if ([currentUser[@"sex"] isEqual:@"Female"]) mfIndex=1;
    else mfIndex=-1;
    if(mfIndex>=0) [_sex setSelectedSegmentIndex:mfIndex];

    int handedIndex;
    if([currentUser[@"handed"] isEqual:@"Left"])handedIndex=0;
    else if ([currentUser[@"handed"] isEqual:@"Right"]) handedIndex=1;
    else handedIndex=-1;
    if(handedIndex>=0) [_handed setSelectedSegmentIndex:handedIndex];

    [_professional setSelected:[currentUser[@"professional"] boolValue]];
    [_collegiate setSelected:[currentUser[@"collegiate"] boolValue]];
    [_amateur setSelected:[currentUser[@"amateur"] boolValue]];
    [_intramural setSelected:[currentUser[@"intramural"] boolValue]];
    [_casual setSelected:[currentUser[@"casual"] boolValue]];
    [_none setSelected:[currentUser[@"none"] boolValue]];

    if(currentUser[@"iAgree"]!=nil){
        [_iAgree setSelected:[currentUser[@"iAgree"] boolValue]];
        [_iDoNotAgree setSelected:![currentUser[@"iAgree"] boolValue]];
        _surveyParagraph.text=@"Thank you for submitting your answers. You may update your answers below at any time.";
    }

    if(currentUser[@"screened"]!=nil){
        [_yes setSelected:[currentUser[@"screened"] boolValue]];
        [_no setSelected:![currentUser[@"screened"] boolValue]];
    }

}

#pragma mark - picker
- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{

    return _ages.count;
}

//-(NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
//    return _ages[row];
//}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = _ages[row];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];

    
    return attString;
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 37)];
    
    if (component == 0) {
        
        //label.font=[UIFont boldSystemFontOfSize:22];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        NSString *title = _ages[row];
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        label.attributedText=attString;
        
        //label.text = [NSString stringWithFormat:@"%@", [_ages objectAtIndex:row]];
        //label.font=[UIFont boldSystemFontOfSize:22];
        
    }
    return label;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    currentUser[@"age"]=[NSNumber numberWithChar:row];
    [currentUser saveEventually];
}

-(IBAction)textFieldReturn:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark - segmented
-(void)segmentSelected:(id)sender{
    
    if([sender tag]==0){
        if(_sex.selectedSegmentIndex==0) currentUser[@"sex"]= @"Male";
        else if(_sex.selectedSegmentIndex==1) currentUser[@"sex"]= @"Female";
        [currentUser saveEventually];
    }
    else if([sender tag]==1){
        if(_handed.selectedSegmentIndex==0) currentUser[@"handed"]= @"Left";
        else if(_handed.selectedSegmentIndex==1) currentUser[@"handed"]= @"Right";
        [currentUser saveEventually];
    }
}




#pragma mark - checkboxes

-(void)checkboxSelected:(id)sender{
    
    if([sender isSelected]==YES) [sender setSelected:NO];
    else [sender setSelected:YES];
    
    float screenHeight=[[UIScreen mainScreen] bounds].size.height;

    
    if([sender tag]==0) currentUser[@"frequentHeadaches"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==1) currentUser[@"dizziness"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==2) currentUser[@"lossOfConsciousness"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==3) currentUser[@"seizures"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==4) currentUser[@"mentalHealth"] = [NSNumber numberWithBool:[sender isSelected]];
    
    else if([sender tag]==5) currentUser[@"narcotics"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==6) currentUser[@"stimulants"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==7) currentUser[@"cocain"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==8) currentUser[@"lsd"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==9) currentUser[@"marijuana"] = [NSNumber numberWithBool:[sender isSelected]];
    else if([sender tag]==10) currentUser[@"streetDrugs"] = [NSNumber numberWithBool:[sender isSelected]];
    
//    else if([sender tag]==11) currentUser[@"professional"] = [NSNumber numberWithBool:[sender isSelected]];
//    else if([sender tag]==12) currentUser[@"collegiate"] = [NSNumber numberWithBool:[sender isSelected]];
//    else if([sender tag]==13) currentUser[@"amateur"] = [NSNumber numberWithBool:[sender isSelected]];
//    else if([sender tag]==14) currentUser[@"intramural"] = [NSNumber numberWithBool:[sender isSelected]];
//    else if([sender tag]==15) currentUser[@"casual"] = [NSNumber numberWithBool:[sender isSelected]];
//    else if([sender tag]==16) currentUser[@"none"] = [NSNumber numberWithBool:[sender isSelected]];

    else if([sender tag]==50){
        currentUser[@"iAgree"] = [NSNumber numberWithBool:YES];
        [_iAgree setSelected:YES];
        [_iDoNotAgree setSelected:NO];
        [(UIScrollView*)self.superview setContentOffset:CGPointMake(0, 0) animated:YES];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showScreening"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showQuestionnaire"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showConsent"];

        [[NSUserDefaults standardUserDefaults] synchronize];

    }
    else if([sender tag]==51){
        currentUser[@"iAgree"] = [NSNumber numberWithBool:NO];
        [_iAgree setSelected:NO];
        [_iDoNotAgree setSelected:YES];
        [(UIScrollView*)self.superview setContentOffset:CGPointMake(0, 0) animated:YES];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showScreening"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showQuestionnaire"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showConsent"];

        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    else if([sender tag]==60){
        currentUser[@"screened"] = [NSNumber numberWithBool:YES];
        [_yes setSelected:YES];
        [_no setSelected:NO];
        UIScrollView *superView=(UIScrollView*)self.superview;

        [superView setContentOffset:CGPointMake(0, screenHeight*1.5+950) animated:YES];
        [superView setContentSize:CGSizeMake(superView.bounds.size.width, 1800+screenHeight*1.5)];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showScreening"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showQuestionnaire"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showConsent"];

        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    else if([sender tag]==61){
        currentUser[@"screened"] = [NSNumber numberWithBool:NO];
        [_yes setSelected:NO];
        [_no setSelected:YES];
        //[(UIScrollView*)self.superview setContentOffset:CGPointMake(0, 0) animated:YES];
        UIScrollView *superView=(UIScrollView*)self.superview;
        [superView setContentOffset:CGPointMake(0, 0) animated:YES];
        [superView setContentSize:CGSizeMake(superView.bounds.size.width, screenHeight*1.5+950)];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showScreening"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showQuestionnaire"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showConsent"];

        [[NSUserDefaults standardUserDefaults] synchronize];

    }
    
    if([sender tag]>=11 && [sender tag]<=16){
        
        //deselect everthing
        [_professional setSelected:NO];
        [_collegiate setSelected:NO];
        [_amateur setSelected:NO];
        [_intramural setSelected:NO];
        [_casual setSelected:NO];
        [_none setSelected:NO];
        
        currentUser[@"professional"]=[NSNumber numberWithBool:NO];
        currentUser[@"collegiate"]=[NSNumber numberWithBool:NO];
        currentUser[@"amateur"]=[NSNumber numberWithBool:NO];
        currentUser[@"intramural"]=[NSNumber numberWithBool:NO];
        currentUser[@"casual"]=[NSNumber numberWithBool:NO];
        currentUser[@"none"]=[NSNumber numberWithBool:NO];


        //turn on selection
        [sender setSelected:YES];
        
        //record hit
        if([sender tag]==11) currentUser[@"professional"] = [NSNumber numberWithBool:[sender isSelected]];
        else if([sender tag]==12) currentUser[@"collegiate"] = [NSNumber numberWithBool:[sender isSelected]];
        else if([sender tag]==13) currentUser[@"amateur"] = [NSNumber numberWithBool:[sender isSelected]];
        else if([sender tag]==14) currentUser[@"intramural"] = [NSNumber numberWithBool:[sender isSelected]];
        else if([sender tag]==15) currentUser[@"casual"] = [NSNumber numberWithBool:[sender isSelected]];
        else if([sender tag]==16) currentUser[@"none"] = [NSNumber numberWithBool:[sender isSelected]];
        
        
        UIScrollView *superView=(UIScrollView*)self.superview;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showScreening"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showQuestionnaire"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showConsent"];
        [superView setContentOffset:CGPointMake(0, screenHeight*1.5+1900) animated:YES];
        [superView setContentSize:CGSizeMake(superView.bounds.size.width, 4000+screenHeight*1.5)];

    }
    
    
    
    [currentUser saveEventually];

    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/



@end
