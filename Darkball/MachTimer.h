// MachTimer.h
#include <mach/mach_time.h>

@interface MachTimer : NSObject
{
    uint64_t timeZero;
}

+ (id) timer;

- (void) start;
- (uint64_t) elapsed;
- (float) elapsedSeconds;
@end
