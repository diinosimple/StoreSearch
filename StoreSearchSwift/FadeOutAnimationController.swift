//
//  FadeOutAnimationController.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/12/23.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import Foundation
import UIKit

class FadeOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.4
    }
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        //This is mostly the same as the other animation controllers. The actual animation simply sets the view’s alpha value to 0 in order to fade it out.
        if let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey) {
            let duration = transitionDuration(transitionContext)
            UIView.animateWithDuration(duration, animations: {
                fromView.alpha = 0
            }, completion: { finished in
                transitionContext.completeTransition(true)
            })
        }
    }
}