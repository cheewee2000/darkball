# Darkball (TATATA) Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the 2015 Objective-C Darkball/TATATA app build on Xcode 26, run full-screen on modern iPhones (iOS 15+), and be App Store–submittable, by removing dead dependencies (Parse/Crashlytics/Facebook/Bolts), storing data locally, and modernizing Game Center.

**Architecture:** Keep the existing Objective-C app intact — same CADisplayLink game loop, same programmatic UI. Replace the Parse backend with two tiny local classes: `LocalUser` (NSUserDefaults-backed, subscript-compatible drop-in for `PFUser`) and `TrialStore` (appends trial records to a JSON file). Modernize GameKit calls in place.

**Tech Stack:** Objective-C, UIKit, GameKit, Xcode 26 / iOS 18 SDK, deployment target iOS 15.0.

## Global Constraints

- Deployment target: **iOS 15.0** (all four config sections in project.pbxproj).
- Objective-C only; no Swift files.
- **Never change gameplay/timing code**: the CADisplayLink `update` loop, MachTimer, ball geometry (`courtWidth=320`), durations, and scoring math are untouched.
- Leaderboard ID stays **`global.tatata`**; bundle ID stays **`com.cwandt.tatata`**.
- Version → **1.3**, build → **160** (in `TATATA/tatata.plist`).
- Project root: `/Users/cwwang/CW&T Dropbox/Che-Wei Wang/My Mac (9.local)/Desktop/Darkball iOS/TATATA` (all paths below relative to it). NOTE the `&` and spaces — always quote paths in shell commands.
- Build command (run from project root):
  `xcodebuild -project Darkball.xcodeproj -scheme Darkball -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
  (Scheme `Darkball` exists; ignore the stale `TATATA` scheme.)
- **Expected build state**: the project does NOT build until Task 4 completes (Tasks 1–4 form the excision arc). First green build is the Task 4 exit gate. Tasks 5–6 must each end with a green build.
- Commit after every task with the trailer:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01KuaBoCtR6PbThE7VoFTwm1`

---

### Task 1: LocalUser + TrialStore classes

**Files:**
- Create: `TATATA/LocalUser.h`, `TATATA/LocalUser.m`
- Create: `TATATA/TrialStore.h`, `TATATA/TrialStore.m`
- Modify: `Darkball.xcodeproj/project.pbxproj` (add 4 file refs, 2 build files to Sources phase, group entries)

**Interfaces:**
- Produces: `LocalUser` — `+ (instancetype)currentUser;` singleton; keyed subscripting (`user[@"key"]`, `user[@"key"] = obj`); `- (void)saveEventually;` `- (void)saveInBackground;` (both no-ops); `- (void)incrementKey:(NSString *)key;`
- Produces: `TrialStore` — `+ (instancetype)shared;` `- (void)appendTrial:(NSDictionary *)trial;` `- (NSURL *)storeURL;`

- [ ] **Step 1: Write LocalUser.h**

```objc
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
```

- [ ] **Step 2: Write LocalUser.m**

```objc
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
```

- [ ] **Step 3: Write TrialStore.h**

```objc
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
```

- [ ] **Step 4: Write TrialStore.m**

```objc
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
```

- [ ] **Step 5: Register the 4 files in project.pbxproj**

Hand-edit `Darkball.xcodeproj/project.pbxproj` (plain text). Add in the **PBXBuildFile** section (top, alphabetical placement irrelevant):

```
		AA0000011AAAAAA100000001 /* LocalUser.m in Sources */ = {isa = PBXBuildFile; fileRef = AA0000021AAAAAA100000002 /* LocalUser.m */; };
		AA0000031AAAAAA100000003 /* TrialStore.m in Sources */ = {isa = PBXBuildFile; fileRef = AA0000041AAAAAA100000004 /* TrialStore.m */; };
```

In the **PBXFileReference** section:

```
		AA0000021AAAAAA100000002 /* LocalUser.m */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.objc; path = LocalUser.m; sourceTree = "<group>"; };
		AA0000051AAAAAA100000005 /* LocalUser.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = LocalUser.h; sourceTree = "<group>"; };
		AA0000041AAAAAA100000004 /* TrialStore.m */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.objc; path = TrialStore.m; sourceTree = "<group>"; };
		AA0000061AAAAAA100000006 /* TrialStore.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = TrialStore.h; sourceTree = "<group>"; };
```

In the main app **PBXGroup** (the group containing `AppDelegate.m` — find `AppDelegate.m in the children list of the TATATA group), add the four new file-reference IDs to `children`. In the **PBXSourcesBuildPhase** `files` list (contains `ViewController.m in Sources`), add the two `.m` build-file IDs.

- [ ] **Step 6: Verify pbxproj integrity**

Run: `plutil -lint Darkball.xcodeproj/project.pbxproj`
Expected: `project.pbxproj: OK`
Also run: `xcodebuild -list -project Darkball.xcodeproj` — must still list scheme `Darkball` without error.

- [ ] **Step 7: Commit**

```bash
git add TATATA/LocalUser.* TATATA/TrialStore.* Darkball.xcodeproj/project.pbxproj
git commit -m "Add LocalUser and TrialStore local persistence classes"
```

---

### Task 2: Project surgery — remove dead frameworks and dead vendored code

**Files:**
- Modify: `Darkball.xcodeproj/project.pbxproj`
- Delete from repo: `Parse.framework/`, `ParseUI.framework/`, `ParseFacebookUtils.framework/`, `ParseCrashReporting.framework/`, `Bolts.framework/`, `Crashlytics.framework/`, `TATATA/KMCGeigerCounter/`, `TATATA/TestFlightSDK3.0.2/` (if present), `TATATA/Reachability.h`, `TATATA/Reachability.m`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: a project that links only live frameworks. Source still references Parse/Reachability — build failures after this task are expected until Task 4.

- [ ] **Step 1: Remove framework/build references from project.pbxproj**

In `Darkball.xcodeproj/project.pbxproj` remove every line/block referencing (grep for each token): `Parse.framework`, `ParseUI`, `ParseFacebookUtils`, `ParseCrashReporting`, `Bolts`, `Crashlytics`, `KMCGeigerCounter`, `Reachability`, `TestFlight`, `libstdc++.6.dylib`, `libsqlite3.dylib`, `libz.dylib`, `StoreKit.framework`, `CoreLocation.framework`, `MediaPlayer.framework`, `SpriteKit.framework`, `CoreAudio.framework`. This covers PBXBuildFile entries, PBXFileReference entries, PBXFrameworksBuildPhase files, PBXGroup children, PBXSourcesBuildPhase (KMCGeigerCounter.m, Reachability.m), and PBXResourcesBuildPhase (KMCGeigerCounterTick.aiff). Remove the KMCGeigerCounter PBXGroup block entirely (it spans multiple lines around former line 154).

Keep linked: GameKit (Weak), AVFoundation, AudioToolbox, QuartzCore, CFNetwork, SystemConfiguration, Security, MobileCoreServices, UIKit, Foundation, CoreGraphics. (Some are now redundant with auto-linking but are harmless.)

- [ ] **Step 2: Remove the Crashlytics run-script phase**

Delete the entire `PBXShellScriptBuildPhase` block (contains `./Crashlytics.framework/run 1eb6...`), remove its ID from the target's `buildPhases` list, and delete the `PBXShellScriptBuildPhase` section header comments if the section is now empty.

- [ ] **Step 3: Clean build settings**

In all four XCBuildConfiguration blocks:
- `IPHONEOS_DEPLOYMENT_TARGET = 7.1;` → `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` (4 occurrences)
- Delete the `LIBRARY_SEARCH_PATHS` blocks referencing `TestFlightSDK3.0.2` (2 occurrences)
- `FRAMEWORK_SEARCH_PATHS` blocks: remove `"$(PROJECT_DIR)"` and `"$(PROJECT_DIR)/TATATA"` entries (they existed only for the bundled frameworks); keep `$(inherited)`.

- [ ] **Step 4: Delete dead directories/files from the repo**

```bash
git rm -r --quiet Parse.framework ParseUI.framework ParseFacebookUtils.framework ParseCrashReporting.framework Bolts.framework Crashlytics.framework "TATATA/KMCGeigerCounter" TATATA/Reachability.h TATATA/Reachability.m
git rm -r --quiet TATATA/TestFlightSDK3.0.2 2>/dev/null || true
```

- [ ] **Step 5: Verify project file integrity**

Run: `plutil -lint Darkball.xcodeproj/project.pbxproj` → `OK`
Run: `grep -c "Parse\|Bolts\|Crashlytics\|KMCGeiger\|Reachability\|TestFlight" Darkball.xcodeproj/project.pbxproj` → Expected: `0`
Run: `xcodebuild -list -project Darkball.xcodeproj` → still lists scheme `Darkball`.
(Do NOT expect `xcodebuild build` to pass yet — sources still import Parse.)

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Remove Parse, Crashlytics, Bolts, Facebook frameworks and dead vendored code; target iOS 15"
```

---

### Task 3: AppDelegate — remove Parse/Crashlytics/push

**Files:**
- Modify: `TATATA/AppDelegate.m`

**Interfaces:**
- Consumes: nothing (run count moves to plain NSUserDefaults).
- Produces: an AppDelegate with no third-party references.

- [ ] **Step 1: Rewrite the top of AppDelegate.m**

Remove imports of `Parse/Parse.h`, `Crashlytics/Crashlytics.h` and the commented TestFlight/ParseCrashReporting/KMCGeigerCounter imports. Replace `application:didFinishLaunchingWithOptions:` in full with:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[defaults integerForKey:@"RunCount"] + 1 forKey:@"RunCount"];

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    return YES;
}
```

(Drops: Parse init keys, PFAnalytics, PFUser enableAutomaticUser/RunCount, Crashlytics start, UIUserNotificationSettings push registration, deprecated `setStatusBarHidden:` — the plist `UIStatusBarHidden` already handles the status bar.)

- [ ] **Step 2: Delete the push-notification delegate methods**

Delete `application:didRegisterForRemoteNotificationsWithDeviceToken:` and `application:didReceiveRemoteNotification:` entirely (they only fed PFInstallation/PFPush).

- [ ] **Step 3: Verify no third-party symbols remain**

Run: `grep -n "Parse\|PF\|Crashlytics\|TestFlight\|KMCGeiger" TATATA/AppDelegate.m`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add TATATA/AppDelegate.m
git commit -m "AppDelegate: remove Parse, Crashlytics, and push registration"
```

---

### Task 4: Excise Parse from ViewController and SurveyView (exit gate: green build)

**Files:**
- Modify: `TATATA/ViewController.h`, `TATATA/ViewController.m`
- Modify: `TATATA/SurveyView.h`, `TATATA/SurveyView.m`

**Interfaces:**
- Consumes: `LocalUser` (`+currentUser`, subscripting, `saveEventually` no-op), `TrialStore` (`+shared`, `appendTrial:`).
- Produces: source tree with zero Parse/Reachability references; app reads/writes all state locally.

- [ ] **Step 1: ViewController.h**

- Replace `#import <Parse/Parse.h>` with `#import "LocalUser.h"` and add `#import "TrialStore.h"`.
- Remove `#import "Reachability.h"`.
- Change ivar `PFObject *currentTrial;` → `NSDictionary *currentTrial;` (at runtime it always held an NSDictionary from `trialArray` after local load).
- Change `@property PFUser *currentUser;` → `@property LocalUser *currentUser;`
- Remove the `NetworkStatus netStatus;` ivar (line ~124).
- Delete the dead macros `IS_IPHONE`, `IS_IPHONE_4/5/6/6_PLUS`, `IS_OS_7_OR_LATER` if they live in ViewController.m lines 5–11 (they are defined but never used).

- [ ] **Step 2: ViewController.m — remove PFConfig fetch (lines ~572–602)**

Delete from the comment `//load configs. defaults in case no internet. too slow` through the closing `}];` of the `[PFConfig getConfigInBackgroundWithBlock:...]` block. The NSUserDefaults-backed defaults immediately above (flashDuration=…, accuracyStart=…, accuracyMax=…, accuracyIncrement=…, nTrialsInStage=5.0) already provide every value.

- [ ] **Step 3: ViewController.m — saveTrialData config version (line ~1306)**

Replace:
```objc
    PFConfig * config = [PFConfig currentConfig];
    NSString *configVersion=config[@"configVersion"];
```
with:
```objc
    NSString *configVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"configVersion"];
```
(Value will be nil; both later uses are already nil-guarded or become part of the local record only when present.)

- [ ] **Step 4: ViewController.m — replace the Parse `results` block (lines ~1361–1416)**

Replace the entire `//save to parse` block — from `if([_currentUser[@"iAgree"] boolValue]){` through its closing `}` after `[pObject saveEventually];` — with:

```objc
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
```

IMPORTANT: this block currently sits AFTER `NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];` (line ~1359) — keep that ordering so `defaults` is in scope. `myDictionary` already contains offset, goal, trialDelay, CATransactionDelay, droppedFrames, flashT, trialIndex, d1, d2, duration, errorWindow, d1Frames, d2Frames, d1Duration, d2Duration, trueD1Duration, trueD2Duration, level, win, date, timezone, touchX, touchY, touchLength, actualD1Duration, build, configVersion.

- [ ] **Step 5: ViewController.m — getTrialSequence (lines ~2153–2185)**

Replace the whole method body with:

```objc
-(void)getTrialSequence{
    NSArray *libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    trialArrayDataFile=[[libPath objectAtIndex:0] stringByAppendingPathComponent:@"trialSequence.dat"];

    [self loadLocalTrialSequence];
}
```

(`loadLocalTrialSequence` already creates a default 2-trial sequence when no file exists — keep it unchanged.)

- [ ] **Step 6: ViewController.m — logIn (lines ~2209–2277)**

Replace the whole method body with:

```objc
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
```

- [ ] **Step 7: ViewController.m — remove Reachability gates**

Three sites:
1. Lines ~851–858 (inside the scroll update): delete the `if(scrollView.contentOffset.y<screenHeight*.5){ Reachability *reach = ... }` block entirely.
2. `setIntroPosition` (~line 880): change
   `if (netStatus != NotReachable && ![[NSUserDefaults standardUserDefaults] boolForKey:@"showIntro1"] && loggedIn) {` →
   `if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showIntro1"] && loggedIn) {`
3. `restart` (~lines 982–986): delete the two Reachability lines and change the condition to:
   `if([[NSUserDefaults standardUserDefaults] boolForKey:@"showScreening"] && _currentUser[@"screened"]==nil ){`
4. `viewDidAppear` (~lines 2130–2140): delete any remaining `Reachability`/`netStatus` logging block.

- [ ] **Step 8: ViewController.m — delete deprecated rotation override**

Delete the `shouldAutorotateToInterfaceOrientation:` method (lines ~2291–2295). Portrait-only is enforced by the plist.

- [ ] **Step 9: SurveyView.h + SurveyView.m**

- SurveyView.h: replace `#import <Parse/Parse.h>` with `#import "LocalUser.h"`; ivar `PFUser *currentUser;` → `LocalUser *currentUser;`
- SurveyView.m line ~26: `currentUser=[PFUser currentUser];` → `currentUser=[LocalUser currentUser];`
- `loadSurveyResults` (~lines 86–140): remove the `[[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {` wrapper and its closing `}];` — keep the body that reads `currentUser[@"age"]` etc. and restores UI, executing it directly (it reads from LocalUser synchronously now). Remove any `if (!error)` guard that came with the block.
- All `[currentUser saveEventually];` and `currentUser[@"…"] = …;` lines stay untouched — LocalUser supports both.

- [ ] **Step 10: Full-source Parse scan**

Run: `grep -rn "PFUser\|PFObject\|PFQuery\|PFConfig\|PFInstallation\|PFAnalytics\|PFPush\|Parse/Parse.h\|Reachability" TATATA/*.h TATATA/*.m`
Expected: no output (commented-out lines containing these tokens should have been deleted along with their blocks; stragglers in comments are acceptable ONLY if inside `//`-comments — prefer deleting them).

- [ ] **Step 11: Build (first green build gate)**

Run: `xcodebuild -project Darkball.xcodeproj -scheme Darkball -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`. Deprecation WARNINGS for GKScore etc. are acceptable here (fixed in Task 5). Fix any errors before committing.

- [ ] **Step 12: Commit**

```bash
git add TATATA/ViewController.* TATATA/SurveyView.*
git commit -m "Replace Parse with LocalUser/TrialStore; remove Reachability gating"
```

---

### Task 5: Modernize Game Center

**Files:**
- Modify: `TATATA/ViewController.m` (three methods)

**Interfaces:**
- Consumes: existing `_gameCenterEnabled` / `_leaderboardIdentifier` properties; leaderboard ID `global.tatata`.
- Produces: GameKit calls that are non-deprecated on iOS 15+.

- [ ] **Step 1: authenticateLocalPlayer (lines ~2298–2326)**

Replace the method with:

```objc
-(void)authenticateLocalPlayer{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil) {
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else if (localPlayer.isAuthenticated) {
            self.gameCenterEnabled = YES;
            self.leaderboardIdentifier = @"global.tatata";
        }
        else {
            self.gameCenterEnabled = NO;
            self.leaderboardIdentifier = nil;
            if (error) NSLog(@"Game Center auth: %@", error.localizedDescription);
        }
    };
}
```

- [ ] **Step 2: reportScore (lines ~1531–1559)**

Replace only the `if(_leaderboardIdentifier){ ... }` tail of the method (the GKScore block) with:

```objc
    if(_leaderboardIdentifier && _gameCenterEnabled){
        [GKLeaderboard submitScore:best
                           context:0
                            player:[GKLocalPlayer localPlayer]
                    leaderboardIDs:@[_leaderboardIdentifier]
                 completionHandler:^(NSError *error) {
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
            }
        }];
    }
```

Keep the local best/lastScore/NSUserDefaults logic above it untouched.

- [ ] **Step 3: showGlobalLeaderboard (lines ~1566–1572)**

Replace with:

```objc
-(void)showGlobalLeaderboard{
    GKGameCenterViewController *gcViewController =
        [[GKGameCenterViewController alloc] initWithLeaderboardID:@"global.tatata"
                                                      playerScope:GKLeaderboardPlayerScopeGlobal
                                                        timeScope:GKLeaderboardTimeScopeAllTime];
    gcViewController.gameCenterDelegate = self;
    [self presentViewController:gcViewController animated:YES completion:nil];
}
```

(`gameCenterViewControllerDidFinish:` stays as-is — still current API.)

- [ ] **Step 4: Build clean of GameKit deprecation warnings**

Run: `xcodebuild -project Darkball.xcodeproj -scheme Darkball -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | grep -i "gkscore\|deprecat" ; echo "---"; xcodebuild -project Darkball.xcodeproj -scheme Darkball -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -3`
Expected: no GKScore deprecation lines; `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add TATATA/ViewController.m
git commit -m "Modernize Game Center to iOS 14+ GameKit APIs"
```

---

### Task 6: Launch screen, Info.plist, privacy manifest, app icon

**Files:**
- Create: `TATATA/LaunchScreen.storyboard`, `TATATA/PrivacyInfo.xcprivacy`
- Modify: `TATATA/tatata.plist`, `TATATA/Images.xcassets/AppIcon.appiconset/Contents.json`, `Darkball.xcodeproj/project.pbxproj`
- Delete: `TATATA/Default.png`, `TATATA/Default@2x.png`, `TATATA/Default-568h@2x.png`, `TATATA/Images.xcassets/LaunchImage.launchimage/`

- [ ] **Step 1: Create TATATA/LaunchScreen.storyboard** (plain black view — matches the app's dark background)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="22505" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina6_1" orientation="portrait" appearance="light"/>
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="22504"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <color key="backgroundColor" red="0.0" green="0.0" blue="0.0" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                        <viewLayoutGuide key="safeArea" id="Bcu-3y-fUS"/>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
</document>
```

Register it in project.pbxproj: PBXFileReference (`lastKnownFileType = file.storyboard; path = LaunchScreen.storyboard;`), PBXBuildFile, add to the TATATA group children and the Resources build phase (use fresh IDs, e.g. `AA0000071AAAAAA100000007` / `AA0000081AAAAAA100000008`).

- [ ] **Step 2: Create TATATA/PrivacyInfo.xcprivacy**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

Register in pbxproj (file ref + build file + group + Resources phase, fresh IDs).

- [ ] **Step 3: Update TATATA/tatata.plist**

- `CFBundleShortVersionString`: `1.2` → `1.3`
- `CFBundleVersion`: `1.59` → `160`
- `UILaunchStoryboardName`: `MainStoryboard` → `LaunchScreen`
- Add `CFBundleDisplayName` → `TATATA` (replace the `$(PRODUCT_NAME:rfc1034identifier)` value)
- `UIRequiredDeviceCapabilities`: replace `armv7`+`gamekit` array with single `arm64`
- Add `<key>ITSAppUsesNonExemptEncryption</key><false/>`
- Delete the empty `CFBundleIcons` / `CFBundleIcons~ipad` dicts
- Keep: portrait-only, `UIStatusBarHidden`, `UIViewControllerBasedStatusBarAppearance=false`, `UIMainStoryboardFile` = MainStoryboard.

- [ ] **Step 4: Modern single-size app icon**

Overwrite `TATATA/Images.xcassets/AppIcon.appiconset/Contents.json` with:

```json
{
  "images" : [
    {
      "filename" : "iTunesArtwork@2x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Delete the now-unreferenced small Icon-*.png files in that directory (keep `iTunesArtwork@2x.png`). Verify it is opaque RGB (App Store rejects alpha): `sips -g hasAlpha "TATATA/Images.xcassets/AppIcon.appiconset/iTunesArtwork@2x.png"` — if `hasAlpha: yes`, flatten: `sips -s format jpeg ... && sips -s format png ...` or use ImageMagick to composite on black.

- [ ] **Step 5: Remove legacy launch images**

```bash
git rm --quiet TATATA/Default.png TATATA/Default@2x.png TATATA/Default-568h@2x.png
git rm -r --quiet TATATA/Images.xcassets/LaunchImage.launchimage
```
In project.pbxproj: remove the three `Default*.png` PBXBuildFile/PBXFileReference/Resources/group entries and both `ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME = LaunchImage;` lines.

- [ ] **Step 6: Build**

Run: `plutil -lint TATATA/tatata.plist && plutil -lint "TATATA/PrivacyInfo.xcprivacy" && xcodebuild -project Darkball.xcodeproj -scheme Darkball -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -3`
Expected: both plists OK; `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Launch storyboard, privacy manifest, modern app icon, Info.plist cleanup; v1.3 (160)"
```

---

### Task 7: Runtime verification in simulator + safe-area check

**Files:**
- Possibly modify: `TATATA/ViewController.m` (only if safe-area verification fails)

- [ ] **Step 1: Boot simulator, install, launch**

```bash
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
xcodebuild -project Darkball.xcodeproj -scheme Darkball -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath build build
xcrun simctl install "iPhone 16 Pro" "build/Build/Products/Debug-iphonesimulator/Darkball.app"
xcrun simctl launch "iPhone 16 Pro" com.cwandt.tatata
```
Expected: app launches without crashing (check `xcrun simctl spawn "iPhone 16 Pro" log stream --predicate 'process == "Darkball"' --style compact` in background for exceptions if needed).

- [ ] **Step 2: Verify full-screen rendering**

```bash
sleep 4 && xcrun simctl io "iPhone 16 Pro" screenshot /tmp/darkball-launch.png
```
Inspect the screenshot (Read tool): the app must fill the entire 6.3" display — no black letterbox bands top/bottom. UI elements (score labels, play button) must not collide with the Dynamic Island or home indicator. If top-of-screen labels sit under the Dynamic Island, add a safe-area offset in ViewController where `screenWidth`/`screenHeight` are captured — shift only the top-anchored HUD labels down by `self.view.safeAreaInsets.top`, never the ball path geometry.

- [ ] **Step 3: Play trials and verify gameplay + data**

Using simctl or manual interaction (ask the user to tap if needed — timing gameplay is human-driven): tap Play, complete at least 2 trials. Then verify the local trial store:

```bash
APPDIR=$(xcrun simctl get_app_container "iPhone 16 Pro" com.cwandt.tatata data)
ls "$APPDIR/Library/Application Support/Darkball/" 2>/dev/null
python3 -m json.tool "$APPDIR/Library/Application Support/Darkball/trials.json" | head -40
```
Expected (only if consent "I agree" was given in the survey; otherwise verify `$APPDIR/Library/trialSequence.dat` exists and `defaults`-backed labels updated): valid JSON array of trial records with offset/d1/d2/duration/uuid keys.

- [ ] **Step 4: Verify survey**

Scroll to the survey/intro view in-app; toggle a checkbox; relaunch the app and confirm the selection persisted (LocalUser → NSUserDefaults). 

- [ ] **Step 5: Final commit + push**

```bash
git add -A && git status --short
git commit -m "Runtime verification fixes" # only if Step 2 required layout tweaks
git push origin master
```

---

## Self-review notes

- Spec coverage: framework removal (T2), local storage (T1/T4), Game Center (T5), launch/icons/privacy/plist (T6), deprecated APIs (T3 setStatusBarHidden, T4 rotation/macros/Reachability), verification (T7). ✓
- `incrementKey:` exists on LocalUser (used nowhere after AppDelegate rewrite, kept for API completeness — acceptable).
- `setIntroPosition` call added at end of new `logIn` (T4 Step 6) because the old async Parse callback set `loggedIn` late; synchronous login means the intro/survey layout must refresh once immediately.
- Type consistency: `currentTrial` becomes NSDictionary; all uses are subscript reads (`currentTrial[@"d1"]` etc.) — compatible.

---

### Task 8: Remove consent form and data logging (scope change, user-directed)

**User direction (2026-07-05):** "remove the consent form and data logging. we just want game play and game center leader board."

**Files:**
- Delete: `TATATA/SurveyView.h`, `TATATA/SurveyView.m`, `TATATA/SurveyView.xib`, `TATATA/LocalUser.h`, `TATATA/LocalUser.m`, `TATATA/TrialStore.h`, `TATATA/TrialStore.m`
- Modify: `TATATA/ViewController.h`, `TATATA/ViewController.m`, `TATATA/AppDelegate.m`, `Darkball.xcodeproj/project.pbxproj`

**Keep (gameplay state, NOT research logging):** best/lastScore/accuracyScore/trialsPlayed in NSUserDefaults, `accuracyHistory` + its file (drives the sparkline), `trialSequence.dat` + `loadLocalTrialSequence`, game config defaults (flashDuration etc.), the intro/instructions view (`intro`, `introHeight`, `showIntro1` flow), all Game Center code.

- [ ] **Step 1: ViewController.h** — remove `#import "LocalUser.h"`, `#import "TrialStore.h"`, `#import "SurveyView.h"`; remove ivars `surveyView`, `surveyHeight`, `screeningHeight`, `questionnaireHeight`, `surveyHeights`, `loggedIn`, `allTrialDataFile`; remove properties `currentUser`, `allTrialData`. KEEP `introHeight` and `intro`.

- [ ] **Step 2: ViewController.m — survey UI removal**
  - ~37–42: delete `surveyHeight=`, `questionnaireHeight=`, `screeningHeight=`, `surveyHeights=` assignments (keep `introHeight=850;`).
  - ~457–460: delete the SurveyView alloc/addSubview block.
  - `setIntroPosition` (~807–843): replace the whole method body with the old "else" branch only:
    ```objc
    -(void)setIntroPosition{
        [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, screenHeight*1.5+introHeight)];
        intro.alpha=1;
    }
    ```
  - Scroll paging math (~855–869): the survey pages no longer exist. In the `_currentPage` computation, collapse the `screeningHeight`/`questionnaireHeight` branches so everything past `screenHeight*1.5` is the last page; in the `pageHeight` computation delete the `_page==3`/`_page==4` survey branches. No reference to `screeningHeight`/`questionnaireHeight` may survive.
  - `restart` (~911–913): delete the `showScreening && _currentUser[@"screened"]==nil` block entirely (intro is handled by the `showIntro1` gate in viewDidAppear).
  - ~993–1001 and ~1031–1035: in the intro-dismiss logic keep `showIntro1 → NO` but delete every line setting/reading `showScreening`, `showQuestionnaire`, `showConsent` (including commented ones).

- [ ] **Step 3: ViewController.m — logging removal in `saveTrialData`**
  - Delete the whole `myDictionary` build (from `NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];` through the `configVersion` conditional set), the `[self.allTrialData addObject:...]` / `writeToFile:` pair, and the entire `iAgree`/`record`/TrialStore block.
  - Delete now-unused locals that only fed the record: `localDateTime`, `configVersion` (verify no other use).
  - KEEP: `float diff=trueD2Duration-d2Duration;` if used by later scoring/labels — check; keep `trialCount++; trialCountLabel.text=...; [defaults setObject:... forKey:@"trialsPlayed"];`, the accuracy computation, `accuracyHistory` append/write, and `accuracyLabel` update.
  - Delete `_currentUser[@"trialsPlayed"]=...`, `_currentUser[@"best"]=...`, `[_currentUser saveEventually];` and the commented `_currentUser`/`accuracyScore` lines.
- [ ] **Step 4: ViewController.m — allTrialData init block (~1363–1378)**: delete the `self.allTrialData` load/create/write block and `allTrialDataFile` path setup. Keep the neighboring accuracyHistory/scoreHistory logic untouched.
- [ ] **Step 5: ViewController.m — logIn removal**: delete the `logIn` method entirely, its call site, `loggedIn=false;` (~1997), and the now-unused `deviceName` method + `#import <sys/utsname.h>` if nothing else uses it. Delete stale comment at ~1807 referencing `_currentUser`.
- [ ] **Step 6: AppDelegate.m**: remove the RunCount NSUserDefaults increment (keep setIdleTimerDisabled + return YES).
- [ ] **Step 7: Repo + pbxproj**: `git rm` the seven deleted files; remove ALL their pbxproj entries (PBXBuildFile, PBXFileReference, group children, Sources phase for SurveyView.m/LocalUser.m/TrialStore.m, Resources phase for SurveyView.xib). The `AA00000*` IDs from Task 1 all go. `plutil -lint` must pass.
- [ ] **Step 8: Verify**
  - `grep -rn "SurveyView\|LocalUser\|TrialStore\|currentUser\|iAgree\|loggedIn\|allTrialData\|showScreening\|showQuestionnaire\|showConsent\|screeningHeight\|questionnaireHeight\|surveyHeight" TATATA/*.h TATATA/*.m Darkball.xcodeproj/project.pbxproj` → no output.
  - Build: `xcodebuild -project Darkball.xcodeproj -scheme Darkball -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.2' build` → `** BUILD SUCCEEDED **`.
- [ ] **Step 9: Commit** — `git add -A && git commit -m "Remove consent survey and research data logging; gameplay + Game Center only"` (+ session trailer).
