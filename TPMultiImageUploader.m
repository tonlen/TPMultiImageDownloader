//
//  TPMultiImageUploader.m
//  ChangNet
//
//  Created by HZ on 16/7/4.
//  Copyright © 2016年 SCHH. All rights reserved.
//

#import "TPMultiImageUploader.h"
#import <objc/runtime.h>
#import <AFNetworking/AFNetworking.h>

#define kUploadServer @""

@interface TPImageUploadReceipt : NSObject
@property (nonatomic, strong) UIImage *image;
/**
 The data task created by the `TPImageUploader`.
 */
@property (nonatomic, strong) NSURLSessionDataTask *task;

/**
 The unique identifier for the success and failure blocks when duplicate requests are made.
 */
@property (nonatomic, strong) NSUUID *receiptID;
@end

@implementation TPImageUploadReceipt

- (instancetype)initWithReceiptID:(NSUUID *)receiptID task:(NSURLSessionDataTask *)task image:(UIImage *)image {
    if (self = [self init]) {
        self.receiptID = receiptID;
        self.task = task;
        self.image = image;
    }
    return self;
}

@end

@interface TPMultiImageUploader()
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) NSMutableArray *activeImageUploadReceipts;

@property (nonatomic, strong) NSMutableArray *loadSuccess;

@end

@implementation TPMultiImageUploader

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.loadSuccess = [NSMutableArray array];
        self.activeImageUploadReceipts = [NSMutableArray array];
        self.sessionManager = [AFHTTPSessionManager manager];
    }
    return self;
}

- (void)upload:(NSArray *)imageArray completion:(void(^)(NSArray *urls))completion failure:(void(^)(NSError *error))failure
{
    dispatch_group_t group = dispatch_group_create();
    __weak __typeof(&*self)weakSelf = self;
    for (UIImage *photo in imageArray) {
        dispatch_group_enter(group);
        [self upload:photo handler:^(id obj, NSError *error) {
            dispatch_group_leave(group);
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (!error) {
                [strongSelf.loadSuccess addObject:obj];
            }else {
                [self cancelAllUpload];
                if (failure) {
                    failure(error);
                }
            }
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion(self.loadSuccess);
        }
    });
}

- (void)upload:(UIImage *)image handler:(void(^)(id obj, NSError *error))handler
{
    if ([self isActiveTaskURLEqualToModel:image]){
        return;
    }
    __weak __typeof(&*self)weakSelf = self;
    NSUUID *uploadID = [NSUUID UUID];
    NSURLSessionDataTask *task = [self.sessionManager POST:kUploadServer parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *data = UIImagePNGRepresentation(image);
        [formData appendPartWithFileData:data name:@"imgs[]" fileName:@"image.jpg" mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if ([strongSelf isContainsUploadID:uploadID]) {
            if (handler) {
                handler(responseObject,nil);
            }
            [strongSelf clearActiveUploadInformation:uploadID];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if ([strongSelf isContainsUploadID:uploadID]) {
            if (handler) {
                handler(nil,error);
            }
            [strongSelf clearActiveUploadInformation:uploadID];
        }
    }];
    TPImageUploadReceipt *receipt = [[TPImageUploadReceipt alloc] initWithReceiptID:uploadID task:task image:image];
    [self.activeImageUploadReceipts addObject:receipt];
}

- (void)cancelAllUpload
{
    for (TPImageUploadReceipt *receipt in self.activeImageUploadReceipts) {
        [receipt.task cancel];
    }
}


- (void)clearActiveUploadInformation:(NSUUID *)downloadID {
    TPImageUploadReceipt *willRemoveReceipt = [self isContainsUploadID:downloadID];
    if (willRemoveReceipt) [self.activeImageUploadReceipts removeObject:willRemoveReceipt];
}

- (BOOL)isActiveTaskURLEqualToModel:(UIImage *)image {
    BOOL isActive = NO;
    for (TPImageUploadReceipt *receipt in self.activeImageUploadReceipts) {
        if ([receipt.image isEqual:image]) {
            isActive = YES;
            break;
        }
    }
    return isActive;
}

- (TPImageUploadReceipt *)isContainsUploadID:(NSUUID *)uuid
{
    TPImageUploadReceipt *containedReceipt;
    for (TPImageUploadReceipt *receipt in self.activeImageUploadReceipts) {
        if ([receipt.receiptID isEqual:uuid]) {
            containedReceipt = receipt;
        }
    }
    return containedReceipt;
}

@end
