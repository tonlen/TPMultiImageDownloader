//
//  TPMultiImageDownloader.h
//  ChangNet
//
//  Created by len on 16/6/15.
//  Copyright © 2016年 letout.cc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TPMultiImageDownloader : NSObject
+ (instancetype)shareDownloader;

- (void)downloadImagesWithURLs:(NSArray *)urls
                       success:(void (^)(NSArray<UIImage *> *images))success
                       failure:(void (^)(NSError *error))failure;
@end
