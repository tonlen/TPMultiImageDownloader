//
//  TPMultiImageDownloader.m
//  ChangNet
//
//  Created by HZ on 16/6/15.
//  Copyright © 2016年 SCHH. All rights reserved.
//

#import "TPMultiImageDownloader.h"
#import <objc/runtime.h>
#import "AFImageDownloader.h"

@interface TPMultiImageDownloader()
@property (nonatomic, strong) NSMutableArray<AFImageDownloadReceipt *> *activeImageDownloadReceipts;
@property (nonatomic, strong) NSMutableArray *downloadImages;
@property (nonatomic, strong) NSMutableArray *downloadFieldURL;
@end

@implementation TPMultiImageDownloader

+ (instancetype)shareDownloader
{
    static TPMultiImageDownloader *shareDownloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareDownloader = [[self alloc] init];
    });
    return shareDownloader;
}

+ (AFImageDownloader *)sharedImageDownloader {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, @selector(sharedImageDownloader)) ?: [AFImageDownloader defaultInstance];
#pragma clang diagnostic pop
}

+ (void)setSharedImageDownloader:(AFImageDownloader *)imageDownloader {
    objc_setAssociatedObject(self, @selector(sharedImageDownloader), imageDownloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.downloadImages = [NSMutableArray array];
        self.downloadFieldURL = [NSMutableArray array];
        self.activeImageDownloadReceipts = [NSMutableArray array];
    }
    return self;
}

- (void)downloadImagesWithURLs:(NSArray *)urls
                      success:(void (^)(NSArray<UIImage *> *images))success
                      failure:(void (^)(NSArray *errors))failure
{
    dispatch_group_t group = dispatch_group_create();
    __weak __typeof(&*self)weakSelf = self;
    [urls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_group_enter(group);
        [self downloadImageURL:obj success:^(UIImage *image) {
            [weakSelf.downloadImages addObject:image];
            // download completion
            dispatch_group_leave(group);
            
        } failure:^(NSError *error) {
            [weakSelf.downloadFieldURL addObject:error];
            dispatch_group_leave(group);
        }];
    }];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (success) {
            success(self.downloadImages);
        }
        if (failure) {
            failure(self.downloadFieldURL);
        }
    });
}

- (void)downloadImageURL:(id)url
              success:(void (^)(UIImage *image))success
              failure:(void (^)(NSError *error))failure
{
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:url];
    }
    if (![url isKindOfClass:[NSURL class]]) {
        return;
    }
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    if ([urlRequest URL] == nil) {
        return;
    }
    
    if ([self isActiveTaskURLEqualToURLRequest:urlRequest]){
        return;
    }
    
    AFImageDownloader *downloader = [[self class] sharedImageDownloader];
    id <AFImageRequestCache> imageCache = downloader.imageCache;
    
    __block UIImage *image;
    //Use the image from the image cache if it exists
    UIImage *cachedImage = [imageCache imageforRequest:urlRequest withAdditionalIdentifier:nil];
    if (cachedImage) {
        if (success) {
            success(cachedImage);
        }
    } else {
        __weak __typeof(&*self)weakSelf = self;
        NSUUID *downloadID = [NSUUID UUID];
        AFImageDownloadReceipt *receipt;
        receipt = [downloader
                   downloadImageForURLRequest:urlRequest
                   withReceiptID:downloadID
                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([strongSelf isContainsDownloadID:downloadID]) {
                           if (success) {
                               success(responseObject);
                           } else if(responseObject) {
                               image = responseObject;
                           }
                           [strongSelf clearActiveDownloadInformation:downloadID];
                       }
                       
                   }
                   failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([strongSelf isContainsDownloadID:downloadID]) {
                           if (failure) {
                               failure(error);
                           }
                           [strongSelf clearActiveDownloadInformation:downloadID];
                       }
                   }];
        
        [self.activeImageDownloadReceipts addObject:receipt];
    }
}

- (void)clearActiveDownloadInformation:(NSUUID *)downloadID {
    AFImageDownloadReceipt *willRemoveReceipt = [self isContainsDownloadID:downloadID];
    if (willRemoveReceipt) [self.activeImageDownloadReceipts removeObject:willRemoveReceipt];
}

- (BOOL)isActiveTaskURLEqualToURLRequest:(NSURLRequest *)urlRequest {
    BOOL isActive = NO;
    for (AFImageDownloadReceipt *receipt in self.activeImageDownloadReceipts) {
        if ([receipt.task.originalRequest.URL.absoluteString isEqualToString:urlRequest.URL.absoluteString]) {
            isActive = YES;
            break;
        }
    }
    return isActive;
}

- (AFImageDownloadReceipt *)isContainsDownloadID:(NSUUID *)uuid
{
    AFImageDownloadReceipt *containedReceipt;
    for (AFImageDownloadReceipt *receipt in self.activeImageDownloadReceipts) {
        if ([receipt.receiptID isEqual:uuid]) {
            containedReceipt = receipt;
        }
    }
    return containedReceipt;
}

@end
