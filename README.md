# TPMultiImageDownloader
基于AFNetworking的多图下载

使用方法

	[[TPMultiImageDownloader shareDownloader] 	downloadImagesWithURLs:array success:^(NSArray<UIImage *> *images) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            weakSelf.groupHead = [[StitchingImage alloc] stitchingWithFrame:CGRectMake(0, 0, 45, 45) images:images];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    } failure:^(NSError *error) {
        
    }];
    
传入URL数组或者URL字符串
