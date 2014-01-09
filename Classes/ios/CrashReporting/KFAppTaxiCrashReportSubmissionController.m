//
//  KFAppTaxiCrashReportUploader.m
//  Pods
//
//  Created by Gunnar Herzog on 02.01.14.
//
//

#import "KFAppTaxiCrashReportSubmissionController.h"

#import "KFAppTaxiCrashController.h"


NSString * const KFAppTaxiCrashReportSubmissionControllerException = @"KFAppTaxiCrashReportSubmissionControllerException";

NSString * const KFAppTaxiCrashReportSubmissionControllerErrorDomain = @"KFAppTaxiCrashReportSubmissionControllerErrorDomain";


@interface KFAppTaxiCrashReportSubmissionController ()

@property (nonatomic, readwrite) NSURL *baseURL;

- (instancetype)initWithURLString:(NSString *)URLString;

@end


#pragma mark - KFAppTaxiCrashReportSubmissionController_NSURLConnection

@interface KFAppTaxiCrashReportSubmissionController_NSURLConnection : KFAppTaxiCrashReportSubmissionController <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, copy) KFAppTaxiCrashReportSubmissionCompletionHandler completionHandler;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic, strong) NSMutableData *responseData;

@end


@implementation KFAppTaxiCrashReportSubmissionController_NSURLConnection

- (void)submitURLRequest:(NSURLRequest *)request completionHandler:(KFAppTaxiCrashReportSubmissionCompletionHandler)completionHandler
{
    self.completionHandler = completionHandler;

    self.statusCode = 200;
    self.responseData = [NSMutableData new];
    
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


- (void)cleanup
{
    self.responseData = nil;
    self.urlConnection = nil;
    self.completionHandler = nil;
}


#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        self.statusCode = [(NSHTTPURLResponse *)response statusCode];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.completionHandler(error);
    [self cleanup];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;

    if (!self.completionHandler)
    {
        return;
    }

    if (!(self.statusCode >= 200 && self.statusCode < 400))
    {
        if ([self.responseData length] == 0)
        {
            error = [NSError errorWithDomain:KFAppTaxiCrashReportSubmissionControllerErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Empty response."}];
        }
        else
        {
            error = [NSError errorWithDomain:KFAppTaxiCrashReportSubmissionControllerErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Sending failed with status code: %ld.", (long)self.statusCode]}];
        }
    }

    self.completionHandler(error);
    [self cleanup];
}

@end


#pragma mark - KFAppTaxiCrashReportSubmissionController_NSURLSession

@interface KFAppTaxiCrashReportSubmissionController_NSURLSession : KFAppTaxiCrashReportSubmissionController
@end


@implementation KFAppTaxiCrashReportSubmissionController_NSURLSession

- (void)submitURLRequest:(NSURLRequest *)request completionHandler:(KFAppTaxiCrashReportSubmissionCompletionHandler)completionHandler
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (!completionHandler)
        {
            return;
        }

        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;

        if (error == nil && !(urlResponse.statusCode >= 200 && urlResponse.statusCode < 400))
        {
            if ([data length] == 0)
            {
                error = [NSError errorWithDomain:KFAppTaxiCrashReportSubmissionControllerErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Empty response."}];
            }
            else
            {
                error = [NSError errorWithDomain:KFAppTaxiCrashReportSubmissionControllerErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Sending failed with status code: %ld.", (long)urlResponse.statusCode]}];
            }
        }

        completionHandler(error);
    }];
    [task resume];
}

@end


#pragma mark - KFAppTaxiCrashReportUploadController

@implementation KFAppTaxiCrashReportSubmissionController

+ (instancetype)submissionControllerWithURLString:(NSString *)URLString
{
    if ([NSURLSession class] != nil)
    {
        return [[KFAppTaxiCrashReportSubmissionController_NSURLSession alloc] initWithURLString:URLString];
    }
    else
    {
        return [[KFAppTaxiCrashReportSubmissionController_NSURLConnection alloc] initWithURLString:URLString];
    }
}


- (instancetype)initWithURLString:(NSString *)URLString
{
    self = [super init];
    if (self)
    {
        self.baseURL = [NSURL URLWithString:URLString];
    }

    return self;
}


- (void)submitURLRequest:(NSURLRequest *)request completionHandler:(KFAppTaxiCrashReportSubmissionCompletionHandler)completionHandler
{
    [NSException raise:KFAppTaxiCrashReportSubmissionControllerException format:@"The abstract message submitURLRequest:completionHandler: must be overridden in a concrete subclass."];
}

@end
