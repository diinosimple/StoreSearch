//
//  DimmingPresentationController.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/12/06.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import Foundation
import UIKit

class DimmingPresentationController: UIPresentationController {
    lazy var dimmingView = GradientView(frame: CGRect.zeroRect)
    
    //The presentationTransitionWillBegin() method is invoked when the new view controller is about to be shown on the screen. Here you create the GradientView object, make it as big as the containerView, and insert it behind everything else in this “container view”.
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, atIndex: 0)
        
        //You set the alpha value of the gradient view to 0 to make it completely transparent and then animate it back to 1 (or 100%) and fully visible, resulting in a simple fade-in. That’s a bit more subtle than making the gradient appear so abruptly.
        dimmingView.alpha = 0
        if let transitionCoordinator = presentedViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({ _ in
                self.dimmingView.alpha = 1
            }, completion:nil)
        }
    }
    //This does the inverse: it animates the alpha value back to 0% to make the gradient view fade out.
    override func dismissalTransitionWillBegin() {
        if let transitionCoordinator = presentedViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({ _ in
                self.dimmingView.alpha = 0
            }, completion:nil)
        }
    }
    override func shouldRemovePresentersView() -> Bool {
        return false
    }
    
}
