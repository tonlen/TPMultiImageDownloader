//
//  TPMultiImageDownloader.h
//  ChangNet
//
//  Created by HZ on 16/6/15.
//  Copyright © 2016年 SCHH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TPMultiImageDownloader : NSObject
+ (instancetype)shareDownloader;

- (void)downloadImagesWithURLs:(NSArray *)urls
                       success:(void (^)(NSArray<UIImage *> *images))success
                       failure:(void (^)(NSArray *errors))failure;
@end
