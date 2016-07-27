//
//  TPMultiImageUploader.h
//  ChangNet
//
//  Created by HZ on 16/7/4.
//  Copyright © 2016年 SCHH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPMultiImageUploader : NSObject
- (void)upload:(NSArray *)imageArray completion:(void(^)(NSArray *urls))completion failure:(void(^)(NSError *error))failure;
@end
