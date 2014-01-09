//
//  KFAppTaxiCrashReportSerialization.h
//  Pods
//
//  Created by Gunnar Herzog on 02.01.14.
//
//

#import <Foundation/Foundation.h>

@protocol KFAppTaxiCrashReportSerialization <NSObject>

- (NSURLRequest *)requestBySerializingCrashReports:(NSSet *)crashReports URL:(NSURL *)url userId:(NSString *)userId contactEmail:(NSString *)contactEmail recordedLog:(NSString *)recordedLog;

@end


@interface KFAppTaxiCrashReportSerializer : NSObject

+ (instancetype)serializer;

@end


@interface KFAppTaxiQuincyKitCrashReportSerializer : KFAppTaxiCrashReportSerializer <KFAppTaxiCrashReportSerialization>

@end
