//
//  KFAppTaxiCrashController.h
//  AppTaxi
//
//  Created by Gunnar Herzog on 02/01/14.
//  Copyright (c) 2014 KF Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KFAppTaxiCrashReportSerialization;
@class KFAppTaxiCrashController, KFAppTaxiCrashReportSerializer;

#define KFAppTaxiLog(fmt, ...) do { if([KFAppTaxiCrashController sharedController].isLoggingEnabled) { NSLog((@"[KFAppTaxi] %s/%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); }} while(0)

@protocol KFAppTaxiCrashControllerDelegate <NSObject>

@optional

- (void)crashControllerWillShowSubmitCrashReportAlert:(KFAppTaxiCrashController *)crashController;

- (void)crashControllerWillStartSendingCrashReports:(KFAppTaxiCrashController *)crashController;

- (void)crashControllerDidFinishSendingCrashReports:(KFAppTaxiCrashController *)crashController;

- (KFAppTaxiCrashReportSerializer<KFAppTaxiCrashReportSerialization> *)crashReportSerializerForCrashController:(KFAppTaxiCrashController *)crashController;

- (NSString *)userIdForCrashController:(KFAppTaxiCrashController *)crashController;

- (NSString *)contactEmailForCrashController:(KFAppTaxiCrashController *)crashController;

- (NSString *)recordedLogForCrashController:(KFAppTaxiCrashController *)crashController;

@end


@interface KFAppTaxiCrashController : NSObject

+ (instancetype)sharedController;

@property (nonatomic, getter = isLoggingEnabled) BOOL loggingEnabled;

@property (nonatomic, copy) NSString *submissionURLString;

@property (nonatomic, getter = isShowingAlwaysButton) BOOL showsAlwaysButton;

@property (nonatomic, weak) id<KFAppTaxiCrashControllerDelegate> delegate;

- (void)start;

@end
