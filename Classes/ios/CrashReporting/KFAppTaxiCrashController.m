//
//  KFAppTaxiCrashController.m
//  AppTaxi
//
//  Created by Gunnar Herzog on 02/01/14.
//  Copyright (c) 2014 KF Interactive. All rights reserved.
//

#import "KFAppTaxiCrashController.h"
#import "KFAppTaxiCrashReportSubmissionController.h"
#import "KFReachability.h"

#import <CrashReporter/CrashReporter.h>


NSString * const KFAppTaxiCrashesDierectory = @"com.kf-apptaxi.crashes";

NSString * const KFAppTaxiCrashFilePrefix = @"CrashReport";

NSString * const KFAppTaxiCrashFileExtension = @"kfacr";

NSString * const KFAppTaxiBundleName = @"KFAppTaxi.bundle";

NSString * const KFAppTaxiCrashReportsDictionaryKey = @"KFAppTaxiCrashReportsDictionary";

NSString * const KFAppTaxiSubmitCrashReportsAutomaticallyKey = @"KFAppTaxiSubmitCrashReportsAutomatically";


NSBundle *KFAppTaxiBundle()
{
    static NSBundle *appTaxiBundle = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:KFAppTaxiBundleName];
        appTaxiBundle = [NSBundle bundleWithPath:path];
    });

    return appTaxiBundle;
}


NSString * KFAppTaxiLocalizedString(NSString *key, NSString *comment)
{
    return NSLocalizedStringFromTableInBundle(key, @"KFAppTaxi", KFAppTaxiBundle(), comment);
}


@interface KFAppTaxiCrashController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) KFReachability *reachability;

@property (nonatomic, strong) NSSet *crashFiles;

@end


@implementation KFAppTaxiCrashController


+ (instancetype)sharedController
{
    static KFAppTaxiCrashController *sharedInstance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^
    {
        sharedInstance = [[KFAppTaxiCrashController alloc] init];
        KFAppTaxiBundle();
    });
    
    return sharedInstance;
}


- (void)setSubmissionURLString:(NSString *)submissionURLString
{
    if (![_submissionURLString isEqualToString:submissionURLString])
    {
        _submissionURLString = submissionURLString;

        if (self.reachability)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:KFReachabilityStatusChangedNotification object:nil];
            [self.reachability stopNotifier];
            self.reachability = nil;
        }

        if ([_submissionURLString length])
        {
            self.reachability = [KFReachability reachabilityForInternetConnection];
            [self.reachability startNotifier];
        }
    }
}


- (void)start
{
    NSAssert(self.submissionURLString != nil, @"Property submissionURLString must be set.");

    self.crashFiles = [self persistingCrashFiles];

    if ([self.crashFiles count] > 0)
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        BOOL shouldSubmitAutomatically = [userDefaults boolForKey:KFAppTaxiSubmitCrashReportsAutomaticallyKey];
        NSMutableDictionary *crashReports = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:KFAppTaxiCrashReportsDictionaryKey]];

        NSSet *nonApprovedCrashFiles = [crashReports keysOfEntriesPassingTest:^BOOL(NSString *file, NSNumber *value, BOOL *stop)
        {
            return [value isEqualToNumber:@NO];
        }];

        if (!shouldSubmitAutomatically && [nonApprovedCrashFiles count] > 0)
        {
            if ([self.delegate respondsToSelector:@selector(crashControllerWillShowSubmitCrashReportAlert:)])
            {
                [self.delegate crashControllerWillShowSubmitCrashReportAlert:self];
            }

            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:KFAppTaxiLocalizedString(@"CrashDataFoundTitle", nil), appName]
                                                                message:[NSString stringWithFormat:KFAppTaxiLocalizedString(@"CrashDataFoundDescription", nil), appName]
                                                               delegate:self
                                                      cancelButtonTitle:KFAppTaxiLocalizedString(@"CrashDontSendReport", nil)
                                                      otherButtonTitles:KFAppTaxiLocalizedString(@"CrashSendReport", nil), nil];
            if (self.isShowingAlwaysButton)
            {
                [alertView addButtonWithTitle:KFAppTaxiLocalizedString(@"CrashSendReportAlways", nil)];
            }
            [alertView show];
        }
        else
        {
            [self sendCrashReports];
        }
    }

    if (![[PLCrashReporter sharedReporter] enableCrashReporter])
    {
        KFAppTaxiLog(@"Could not activate KFAppTaxi CrashReporter");
    }
    else
    {
        KFAppTaxiLog(@"KFAppTaxi CrashReporter started");
    }
}


- (id)init
{
    self = [super init];
    if (self)
    {
        self.fileManager = [NSFileManager new];

        if ([[PLCrashReporter sharedReporter] hasPendingCrashReport])
        {
            [self handleCrashReport];
        }
    }
    return self;
}


- (NSSet *)persistingCrashFiles
{
    NSMutableSet *crashFiles;
    NSString *crashesPath = [self crashesPath];
    if ([self.fileManager fileExistsAtPath:crashesPath])
    {
        crashFiles = [NSMutableSet set];

        NSString *file = nil;

        NSDirectoryEnumerator *pathEnumerator = [self.fileManager enumeratorAtPath:crashesPath];

        while ((file = [pathEnumerator nextObject]))
        {
            if ([file.pathExtension isEqualToString:KFAppTaxiCrashFileExtension])
            {
                [crashFiles addObject:file];
            }
        }
    }

    return crashFiles;
}


- (NSString *)crashesPath
{
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:KFAppTaxiCrashesDierectory];
}


- (void)handleCrashReport
{
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSData *crashData = [crashReporter loadPendingCrashReportData];

    if (crashData != nil)
    {
        NSString *crashesPath = [self crashesPath];
        if (![self.fileManager fileExistsAtPath:crashesPath])
        {
            [self.fileManager createDirectoryAtPath:crashesPath withIntermediateDirectories:YES attributes:@{NSURLIsExcludedFromBackupKey : @YES} error:nil];
        }

        NSString *crashFilename = [NSString stringWithFormat: @"%@_%.0f.%@", KFAppTaxiCrashFilePrefix, [NSDate timeIntervalSinceReferenceDate], KFAppTaxiCrashFileExtension];
        [crashData writeToFile:[crashesPath stringByAppendingPathComponent:crashFilename] atomically:YES];

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *crashReports = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:KFAppTaxiCrashReportsDictionaryKey]];
        [crashReports setObject:@NO forKey:crashFilename];
        [userDefaults setObject:crashReports forKey:KFAppTaxiCrashReportsDictionaryKey];
        [userDefaults synchronize];
    }
    [crashReporter purgePendingCrashReport];
}


- (void)sendCrashReports
{
    NSMutableSet *crashReports = [NSMutableSet set];

    NSString *crashesPath = [self crashesPath];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *persistedCrashReports = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:KFAppTaxiCrashReportsDictionaryKey]];

    for (NSString *file in self.crashFiles)
    {
        NSError *error = nil;
        NSData *crashData = [NSData dataWithContentsOfFile:[crashesPath stringByAppendingPathComponent:file]];
        PLCrashReport *report = [[PLCrashReport alloc] initWithData:crashData error:&error];

        if (report && !error)
        {
            [crashReports addObject:report];
        }

        [persistedCrashReports setObject:@YES forKey:file];
        [userDefaults setObject:persistedCrashReports forKey:KFAppTaxiCrashReportsDictionaryKey];
    }
    [userDefaults synchronize];

    if ([crashReports count] > 0)
    {
        __weak typeof(self)weakSelf = self;
        KFAppTaxiCrashReportSubmissionController *submissionController = [KFAppTaxiCrashReportSubmissionController submissionControllerWithURLString:self.submissionURLString];
        submissionController.delegate = self.delegate;

        KFAppTaxiCrashReportSerializer<KFAppTaxiCrashReportSerialization> *crashReportSerializer;
        if ([self.delegate respondsToSelector:@selector(crashReportSerializerForCrashController:)])
        {
            crashReportSerializer = [self.delegate crashReportSerializerForCrashController:self];
            NSAssert(crashReportSerializer != nil, @"crashReportSerializer must not be nil.");
        }
        else
        {
            crashReportSerializer = [KFAppTaxiQuincyKitCrashReportSerializer serializer];
        }

        NSString *userId, *contactEmail, *recordedLog;
        if ([self.delegate respondsToSelector:@selector(userIdForCrashController:)])
        {
            userId = [self.delegate userIdForCrashController:self];
        }
        if ([self.delegate respondsToSelector:@selector(contactEmailForCrashController:)])
        {
            contactEmail = [self.delegate contactEmailForCrashController:self];
        }
        if ([self.delegate respondsToSelector:@selector(recordedLogForCrashController:)])
        {
            recordedLog = [self.delegate recordedLogForCrashController:self];
        }

        if (self.reachability.currentReachabilityStatus == KFReachabilityNetworkStatusNotReachable)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:KFReachabilityStatusChangedNotification object:nil];
            return;
        }

        NSURLRequest *request = [crashReportSerializer requestBySerializingCrashReports:crashReports URL:submissionController.baseURL userId:userId contactEmail:contactEmail recordedLog:recordedLog];

        if ([self.delegate respondsToSelector:@selector(crashControllerWillStartSendingCrashReports:)])
        {
            [self.delegate crashControllerWillStartSendingCrashReports:self];
        }

        [submissionController submitURLRequest:request completionHandler:^(NSError *error)
        {
            if ([weakSelf.delegate respondsToSelector:@selector(crashControllerDidFinishSendingCrashReports:)])
            {
                [weakSelf.delegate crashControllerDidFinishSendingCrashReports:weakSelf];
            }

            if (!error)
            {
                [weakSelf cleanup];
            }
            else
            {
                KFAppTaxiLog(@"ERROR: Sending crash reports failed with error: %@", error.debugDescription);
            }
        }];
    }
}


- (void)cleanup
{
    [self.fileManager removeItemAtPath:[self crashesPath] error:nil];
    self.crashFiles = nil;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:KFAppTaxiCrashReportsDictionaryKey];
    [userDefaults synchronize];
}


#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 1:
            [self sendCrashReports];
            break;
        case 2:
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:KFAppTaxiSubmitCrashReportsAutomaticallyKey];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [self sendCrashReports];
            break;
        }
        default:
            [self cleanup];
            break;
    }
}


#pragma mark - KFReachability change notification

- (void) reachabilityChanged:(NSNotification *)note
{
    if (self.reachability.currentReachabilityStatus != KFReachabilityNetworkStatusNotReachable)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:KFReachabilityStatusChangedNotification object:nil];

        [self sendCrashReports];
    }
}


@end
