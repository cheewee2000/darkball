#import "TrialStore.h"

@interface TrialStore ()
@property (nonatomic, strong) dispatch_queue_t writeQueue;
@end

@implementation TrialStore

+ (instancetype)shared {
    static TrialStore *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[TrialStore alloc] init];
        shared.writeQueue = dispatch_queue_create("com.cwandt.tatata.trialstore", DISPATCH_QUEUE_SERIAL);
    });
    return shared;
}

- (NSURL *)storeURL {
    NSURL *appSupport = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                                inDomain:NSUserDomainMask
                                                       appropriateForURL:nil
                                                                  create:YES
                                                                   error:NULL];
    NSURL *dir = [appSupport URLByAppendingPathComponent:@"Darkball" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    return [dir URLByAppendingPathComponent:@"trials.json"];
}

// NSJSONSerialization can't encode NSDate; convert to ISO 8601 strings.
- (id)jsonSafeValue:(id)value {
    if ([value isKindOfClass:[NSDate class]]) {
        NSISO8601DateFormatter *fmt = [[NSISO8601DateFormatter alloc] init];
        return [fmt stringFromDate:value];
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *out = [NSMutableDictionary dictionary];
        [value enumerateKeysAndObjectsUsingBlock:^(id k, id v, BOOL *stop) {
            out[[k description]] = [self jsonSafeValue:v];
        }];
        return out;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *out = [NSMutableArray array];
        for (id v in value) [out addObject:[self jsonSafeValue:v]];
        return out;
    }
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]] || value == [NSNull null]) {
        return value;
    }
    return [value description];
}

- (void)appendTrial:(NSDictionary *)trial {
    NSDictionary *record = [self jsonSafeValue:trial];
    dispatch_async(self.writeQueue, ^{
        NSURL *url = [self storeURL];
        NSMutableArray *records = [NSMutableArray array];
        NSData *existing = [NSData dataWithContentsOfURL:url];
        if (existing.length) {
            NSArray *parsed = [NSJSONSerialization JSONObjectWithData:existing options:0 error:NULL];
            if ([parsed isKindOfClass:[NSArray class]]) [records addObjectsFromArray:parsed];
        }
        [records addObject:record];
        NSData *out = [NSJSONSerialization dataWithJSONObject:records options:NSJSONWritingPrettyPrinted error:NULL];
        if (out) {
            NSError *writeError = nil;
            if (![out writeToURL:url options:NSDataWritingAtomic error:&writeError]) {
                NSLog(@"TrialStore write failed: %@", writeError);
            }
        }
    });
}

@end
