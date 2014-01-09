//
//  ATViewController.m
//  AppTaxi
//
//  Created by Gunnar Herzog on 09/01/14.
//  Copyright (c) 2014 KF Interactive. All rights reserved.
//

#import "ATViewController.h"
#import "KFAppTaxiCrashController.h"
#import "KFAppTaxiCrashReportSerialization.h"

@interface ATViewController () <KFAppTaxiCrashControllerDelegate>

@end

@implementation ATViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    [KFAppTaxiCrashController sharedController].delegate = self;
    [KFAppTaxiCrashController sharedController].loggingEnabled = YES;
//    [KFAppTaxiCrashController sharedController].submissionURLString = @"YOUR SERVER ADDRESS HERE";
    [KFAppTaxiCrashController sharedController].submissionURLString = @"http://quincy.app-distribution.com/crash_v200.php";
    [KFAppTaxiCrashController sharedController].showsAlwaysButton = YES;
    [[KFAppTaxiCrashController sharedController] start];
}


- (IBAction)crashAppAction:(id)sender
{
    [[NSMutableArray array] addObject:nil];
}


#pragma mark - KFAppTaxiCrashControllerDelegate

- (void)crashControllerWillStartSendingCrashReports:(KFAppTaxiCrashController *)crashController
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}


- (void)crashControllerDidFinishSendingCrashReports:(KFAppTaxiCrashController *)crashController
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


- (void)crashControllerWillShowSubmitCrashReportAlert:(KFAppTaxiCrashController *)crashController
{
    NSLog(@"crashControllerWillShowSubmitCrashReportAlert: called");
}


- (id)crashReportSerializerForCrashController:(KFAppTaxiCrashController *)crashController
{
    return [KFAppTaxiQuincyKitCrashReportSerializer serializer];
}


- (NSString *)recordedLogForCrashController:(KFAppTaxiCrashController *)crashController
{
    return @"This log will be attached to your log file";
}


@end
