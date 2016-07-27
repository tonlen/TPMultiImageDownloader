# TPMultiImageDownloader
基于AFNetworking的多图下载

使用方法

	[[[TPMultiImageDownloader alloc] init] downloadImagesWithURLs:array success:^(NSArray<UIImage *> *images) {
		__typeof__(self)strongSelf = weakSelf;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			strongSelf.groupHeadImage = [[StitchingImage alloc] stitchingWithSize:CGSizeMake(60, 60) images:images];
			[UIImagePNGRepresentation(strongSelf.groupHeadImage) writeToFile:[self headCachePath] atomically:NO];
			DLog(@"1拼接完成%@",[NSThread currentThread]);
			dispatch_async(dispatch_get_main_queue(), ^{
				avatar();
			});
		});
		DLog(@"2图片下载完成%@",[NSThread currentThread]);
	} failure:^(NSArray *errors) {
		Dlog(@"下载失败的图片%@",errors);
	}];
    
创建一个TPMultiImageDownloader对象，使用`downloadImagesWithURLs:success:failure:`方法来下载图片，传入NSURL数组或者URL字符串数组。
