//
//  TrialStore.h
//  Darkball
//
//  Local replacement for Parse "results" logging. Appends one JSON
//  record per trial to Application Support/Darkball/trials.json.
//

#import <Foundation/Foundation.h>

@interface TrialStore : NSObject

+ (instancetype)shared;
- (void)appendTrial:(NSDictionary *)trial;
- (NSURL *)storeURL;

@end
