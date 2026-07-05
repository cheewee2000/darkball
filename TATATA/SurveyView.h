//
//  SurveyView.h
//  Darkball
//
//  Created by Che-Wei Wang on 1/15/15.
//
//

#import <UIKit/UIKit.h>
#import "Dots.h"
#import "LocalUser.h"


@interface SurveyView : UIView <UIPickerViewDelegate, UIPickerViewDataSource>
{
    #pragma mark - intro
    //UIView *intro;
    //    UILabel* introTitle;
    //    UILabel* introSubtitle;
    //    UILabel* introParagraph;
    //UILabel* credits;
    //IBOutlet UIPickerView *agePicker;
    Dots *catchZone;
    UIButton *catchZoneButton;
    LocalUser *currentUser;
    

}
@property (strong, nonatomic) NSArray *ages;
@property (strong, nonatomic) IBOutlet UILabel *surveyParagraph;

@property(strong, nonatomic)  IBOutlet UIButton *yes;
@property(strong, nonatomic)  IBOutlet UIButton *no;

@property (strong, nonatomic) IBOutlet UIPickerView *agePicker;
@property(strong, nonatomic)  IBOutlet UISegmentedControl *sex;
@property(strong, nonatomic)  IBOutlet UISegmentedControl *handed;

@property(strong, nonatomic)  IBOutlet UIButton *professional;
@property(strong, nonatomic)  IBOutlet UIButton *collegiate;
@property(strong, nonatomic)  IBOutlet UIButton *amateur;
@property(strong, nonatomic)  IBOutlet UIButton *intramural;
@property(strong, nonatomic)  IBOutlet UIButton *casual;
@property(strong, nonatomic)  IBOutlet UIButton *none;

@property(strong, nonatomic)  IBOutlet UIButton *iAgree;
@property(strong, nonatomic)  IBOutlet UIButton *iDoNotAgree;


-(void)checkboxSelected:(id)sender;
-(void)loadSurveyResults;



@end
