#import "LocalUser.h"

static NSString *const kLocalUserDefaultsKey = @"localUser";

@implementation LocalUser

+ (instancetype)currentUser {
    static LocalUser *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LocalUser alloc] init];
    });
    return shared;
}

- (NSDictionary *)storedDictionary {
    NSDictionary *d = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLocalUserDefaultsKey];
    return d ?: @{};
}

- (id)objectForKeyedSubscript:(NSString *)key {
    id value = [self storedDictionary][key];
    return (value == [NSNull null]) ? nil : value;
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    NSMutableDictionary *d = [[self storedDictionary] mutableCopy];
    if (obj == nil) [d removeObjectForKey:key];
    else d[key] = obj;
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:kLocalUserDefaultsKey];
}

- (void)incrementKey:(NSString *)key {
    NSNumber *current = [self objectForKeyedSubscript:key];
    self[key] = @([current longLongValue] + 1);
}

- (void)saveEventually { /* values persist on set */ }
- (void)saveInBackground { /* values persist on set */ }

@end
