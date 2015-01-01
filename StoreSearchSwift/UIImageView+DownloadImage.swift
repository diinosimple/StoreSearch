//
//  UIImageView+DownloadImage.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/12/06.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    func loadImageWithURL(url: NSURL) -> NSURLSessionDownloadTask {
        let session = NSURLSession.sharedSession()
        //After obtaining a reference to the shared NSURLSession, you create a download task. This is similar to a data task but it saves the downloaded file to a temporary location on disk instead of keeping it in memory.
        let downloadTask = session.downloadTaskWithURL(url,
            completionHandler: { [weak self] url, response, error in
                //Inside the completion handler for the download task you’re given a URL where you can find the downloaded file (this URL points to a local file rather than an internet address). Of course, you must also check that error is nil before you continue.
                if error == nil && url != nil {
                    //With this local URL you can load the file into an NSData object and then make an image from that. It’s possible that constructing the UIImage fails, when what you downloaded was not a valid image but a 404 page or something else unexpected. As you can tell, when dealing with networking code you need to check for errors every step of the way!
                    if let data = NSData(contentsOfURL: url) {
                        //println("loadImageWithURL->downloaded : \(url)")
                        if let image = UIImage(data: data) {
                            //Once you have the image you can put it into the UIImageView’s image property. Because this is UI code you need to do this on the main thread.
                            //Here’s the tricky thing: it is theoretically possible that the UIImageView no longer exists by the time the image arrives from the server. After all, it may take a few seconds and the user can still navigate through the app in the mean time.
                            //That won’t happen in this part of the app because the image view is part of a table view cell and they get recycled but not thrown away. But later in the tutorial you’ll use this same code to load an image on a detail pop-up that may be closed while the image is still downloading. In that case you don’t want to set the image on the UIImageView anymore.
                            //That’s why the capture list for this closure includes [weak self], where self now refers to the UIImageView. Inside the dispatch_async() block you need to check whether “self” still exists; if not, then there is no more UIImageView to set the image on.
                            dispatch_async(dispatch_get_main_queue()) {
                                if let strongSelf = self {
                                    strongSelf.image = image
                                }
                            }
                        }
                    }
                }
        })
        //After creating the download task you call resume() to start it, and then return the NSURLSessionDownloadTask object to the caller. Why return it? That gives the app the opportunity to call cancel() on the download task. You’ll see how that works in a minute.
        downloadTask.resume()
        return downloadTask
    }
}
