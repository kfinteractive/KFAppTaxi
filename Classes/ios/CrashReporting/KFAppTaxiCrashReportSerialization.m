//
//  KFAppTaxiCrashReportSerialization.m
//  Pods
//
//  Created by Gunnar Herzog on 02.01.14.
//
//

#import "KFAppTaxiCrashReportSerialization.h"

#import <CrashReporter/CrashReporter.h>

#include <sys/sysctl.h>



#pragma mark - KFAppTaxiCrashReportSerializer

@implementation KFAppTaxiCrashReportSerializer

+ (instancetype)serializer
{
    return [[self alloc] init];
}

@end



#pragma mark - KFAppTaxiQunicyKitCrashReportSerializer

@interface KFAppTaxiQuincyKitCrashReportSerializer ()

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *contactEmail;
@property (nonatomic, copy) NSString *recordedLog;

@end


@implementation KFAppTaxiQuincyKitCrashReportSerializer

- (id)init
{
    self = [super init];
    if (self)
    {
        _userId = @"";
        _contactEmail = @"";
        _recordedLog = @"";
    }
    return self;
}


- (NSURLRequest *)requestBySerializingCrashReports:(NSSet *)crashReports URL:(NSURL *)url userId:(NSString *)userId contactEmail:(NSString *)contactEmail recordedLog:(NSString *)recordedLog
{
    if (userId)
    {
        self.userId = userId;
    }

    if (contactEmail)
    {
        self.contactEmail = contactEmail;
    }

    if (recordedLog)
    {
        self.recordedLog = recordedLog;
    }

    NSString *boundary = @"----FOO";

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
    [request setValue:@"Quincy/iOS" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setTimeoutInterval: 15];
    [request setHTTPMethod:@"POST"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-type"];

    NSMutableData *postBody =  [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"xmlstring\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

    NSString *xml = [self crashReportXMLStringFromCrashReports:crashReports];

    [postBody appendData:[xml dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPBody:postBody];

    return request;
}


- (NSString *)getDevicePlatform
{
    size_t size = 0;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *answer = (char*)malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return platform;
}


- (NSString *)crashReportXMLStringFromCrashReports:(NSSet *)crashReports
{
    NSMutableString *crashes = [NSMutableString string];

    for (PLCrashReport *report in crashReports)
    {
        NSString *formattedReport = [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat:PLCrashReportTextFormatiOS];

        if (formattedReport != nil)
        {
            [crashes appendFormat:@"<crash><applicationname>%s</applicationname><bundleidentifier>%@</bundleidentifier><systemversion>%@</systemversion><platform>%@</platform><senderversion>%@</senderversion><version>%@</version><log><![CDATA[%@]]></log><userid>%@</userid><contact>%@</contact><description><![CDATA[%@]]></description></crash>", [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"] UTF8String], report.applicationInfo.applicationIdentifier, report.systemInfo.operatingSystemVersion, [self getDevicePlatform],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], report.applicationInfo.applicationVersion, [formattedReport stringByReplacingOccurrencesOfString:@"]]>" withString:@"]]" @"]]><![CDATA[" @">" options:NSLiteralSearch range:NSMakeRange(0, [formattedReport length])], self.userId, self.contactEmail, [self.recordedLog stringByReplacingOccurrencesOfString:@"]]>" withString:@"]]" @"]]><![CDATA[" @">" options:NSLiteralSearch range:NSMakeRange(0, [self.recordedLog length])]];
        }
    }

    return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><crashes>%@</crashes>", crashes];
}

@end
