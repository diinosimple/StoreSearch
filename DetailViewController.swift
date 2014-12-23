//
//  DetailViewController.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/12/06.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    
    var searchResult: SearchResult!
    var downloadTask: NSURLSessionDownloadTask?
    
    enum AnimationStyle {
        case Slide
        case Fade
    }
    
    //The dismissAnimationStyle variable determines which animation is chosen. This variable is of type AnimationStyle, so it can only contain one of the values from that enum. By default it is .Fade, the animation used when rotating to landscape.
    var dismissAnimationStyle = AnimationStyle.Fade
    
    //Recall that init(coder) is invoked to load the view controller from the storyboard. Here you tell UIKit that this view controller uses a custom presentation and you set the delegate that will call the method you just implemented.
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .Custom
        transitioningDelegate = self
    }
    
    deinit {
        println("deinit \(self)")
        downloadTask?.cancel()
    }
    
    @IBAction func close() {
        dismissAnimationStyle = .Slide
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clearColor()
        
        popupView.layer.cornerRadius = 10
        view.tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255,
            alpha: 1)
        
        //This creates the new gesture recognizer that listens to taps anywhere in this view controller and calls the close() method in response.
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("close"))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        if searchResult != nil {
            updateUI()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUI() {
        nameLabel.text = searchResult.name
        
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = "Unknown"
        } else {
            artistNameLabel.text = searchResult.artistName
        }
        
        kindLabel.text = searchResult.kindForDisplay()
        genreLabel.text = searchResult.genre
        
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.currencyCode = searchResult.currency
        
        var priceText: String
        if searchResult.price == 0 {
            priceText = "Free"
        } else if let text = formatter.stringFromNumber(searchResult.price) {
            priceText = text
        } else {
            priceText = ""
        }
        priceButton.setTitle(priceText, forState: .Normal)
        
        //println("searchResult.artworkURL100: \(searchResult.artworkURL100)")
        if let url = NSURL(string: searchResult.artworkURL100) {
            downloadTask = artworkImageView.loadImageWithURL(url)
        }
    }
    
    
    @IBAction func openInStore() {
        //println("openInStore: \(searchResult.storeURL)")
        if let url = NSURL(string: searchResult.storeURL) {
            UIApplication.sharedApplication().openURL(url)
            
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//The standard presentation controller removed the underlying view from the screen, making it appear as if the Detail pop-up had a solid black background. Removing the view makes sense most of the time when you present a modal screen, as the user won’t be able to see the previous screen anyway (not having to redraw this view saves battery power too).
//However, in our case the modal segue leads to a view controller that only partially covers the previous screen. You want to keep the underlying view to get the see- through effect. That’s why you needed to supply your own presentation controller object.

extension DetailViewController: UIViewControllerTransitioningDelegate {
    //The methods from this delegate protocol tell UIKit what objects it should use to perform the transition to the Detail View Controller. It will now use your new DimmingPresentationController class instead of the standard presentation controller.
    func presentationControllerForPresentedViewController( presented: UIViewController,
        presentingViewController presenting: UIViewController!, sourceViewController source: UIViewController)
        -> UIPresentationController? {
        
        return DimmingPresentationController( presentedViewController: presented,
        presentingViewController: presenting)
    }
    
    func animationControllerForPresentedController( presented: UIViewController,
        presentingController presenting: UIViewController, sourceController source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
        return BounceAnimationController()
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch dismissAnimationStyle {
        case .Slide:
            return SlideOutAnimationController()
        case .Fade:
            return FadeOutAnimationController()
        }
        
    }
}

extension DetailViewController: UIGestureRecognizerDelegate {
            
        ////You only want to close the Detail screen when the user taps outside the pop-up, i.e. on the background. Any other taps should be ignored. That’s what this delegate method is for. It only returns true when the touch was on the background view but false if it was inside the Pop-up View.

        func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
            return (touch.view == view)
        }
}
