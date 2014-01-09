//
//  KFAppTaxiCrashReportUploader.h
//  Pods
//
//  Created by Gunnar Herzog on 02.01.14.
//
//

#import <Foundation/Foundation.h>

#import "KFAppTaxiCrashReportSerialization.h"

@protocol KFAppTaxiCrashControllerDelegate;


extern NSString * const KFAppTaxiCrashReportSubmissionControllerException;

extern NSString * const KFAppTaxiCrashReportSubmissionControllerErrorDomain;


typedef void(^KFAppTaxiCrashReportSubmissionCompletionHandler)(NSError *error);


@interface KFAppTaxiCrashReportSubmissionController : NSObject

+ (instancetype)submissionControllerWithURLString:(NSString *)URLString;

@property (nonatomic, readonly) NSURL *baseURL;

@property (nonatomic, weak) id<KFAppTaxiCrashControllerDelegate> delegate;

- (void)submitURLRequest:(NSURLRequest *)request completionHandler:(KFAppTaxiCrashReportSubmissionCompletionHandler)completionHandler;

@end
