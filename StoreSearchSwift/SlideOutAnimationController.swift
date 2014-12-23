//
//  SlideOutAnimationController.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/12/07.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import Foundation
import UIKit

class SlideOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.3
    }
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey) {
            let duration = transitionDuration(transitionContext)
            let containerView = transitionContext.containerView()
            
            UIView.animateWithDuration(duration, animations: {
                    //you subtract the height of the screen from the view’s center position while simultaneously zooming it out to 50% of its original size, making the Detail screen fly up-up-and-away.
                    fromView.center.y -= containerView.bounds.size.height
                    fromView.transform = CGAffineTransformMakeScale(0.5, 0.5)
                },completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
}