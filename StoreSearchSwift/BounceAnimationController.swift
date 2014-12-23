//
//  BounceAnimationController.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/12/07.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import Foundation
import UIKit

class BounceAnimationController: NSObject,UIViewControllerAnimatedTransitioning {
    
    //This determines how long the animation is. You’re making the pop-in animation last for only 0.4 seconds but that’s long enough. Animations are fun but they shouldn’t keep the user waiting.
    func transitionDuration(transitionContext:UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.4
    }

    //This performs the actual animation.
    func animateTransition(transitionContext:UIViewControllerContextTransitioning) {
        //To find out what to animate, you look at the transitionContext parameter. This gives you a reference to new view controller and lets you know how big it should be.
        if let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) {
            if let toView = transitionContext.viewForKey(UITransitionContextToViewKey) {
                toView.frame = transitionContext.finalFrameForViewController(toViewController)
                let containerView = transitionContext.containerView()
                containerView.addSubview(toView)
            
                //The animation starts with the view scaled down to 70% (scale 0.7).
                toView.transform = CGAffineTransformMakeScale(0.7, 0.7)
            
                UIView.animateKeyframesWithDuration(transitionDuration(transitionContext), delay: 0.0,
                                options: .CalculationModeCubic, animations: {
                    //The next keyframe inflates it to 120% its normal size
                    UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.334, animations: {
                        toView.transform = CGAffineTransformMakeScale(1.2, 1.2)
                    })
                    //After that, it will scale the view down a bit again but not as much as before (only 90% of its original size).
                    UIView.addKeyframeWithRelativeStartTime(0.334, relativeDuration: 0.333, animations: { toView.transform = CGAffineTransformMakeScale(0.9, 0.9)
                    })
                    //The final keyframe ends up with a scale of 1.0, which restores the view to an undistorted shape.
                    UIView.addKeyframeWithRelativeStartTime(0.666, relativeDuration: 0.333, animations: { toView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    })
                    }, completion: { finished in
                    transitionContext.completeTransition(finished)
                })
            
            }
        }
    }
}