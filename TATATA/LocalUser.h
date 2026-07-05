//
//  LocalUser.h
//  Darkball
//
//  NSUserDefaults-backed replacement for the old anonymous PFUser.
//

#import <Foundation/Foundation.h>

@interface LocalUser : NSObject

+ (instancetype)currentUser;

- (id)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;
- (void)incrementKey:(NSString *)key;

// Persistence happens immediately in the setter; these exist so the
// PFUser call sites keep reading naturally.
- (void)saveEventually;
- (void)saveInBackground;

@end
