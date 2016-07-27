# TPMultiImageDownloader
基于AFNetworking的多图下载

使用方法

	__weak __typeof(&*self)weakSelf = self;
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

# TPMultiImageUploader
基于AFNetworking的多图上传

使用方法

	[[[TPMultiImageUploader alloc] init] upload:photos completion:^(NSArray *urls){
		DLog(@"图片上传成功");
	} failure:^(NSError *error) {
		DLog(@"上传失败了");
	}];
上传失败：当有一张图失败，取消其他所有上传，回调失败。