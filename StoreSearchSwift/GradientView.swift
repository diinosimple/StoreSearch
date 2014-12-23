//
//  GradientView.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/12/07.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import UIKit

class GradientView: UIView {

    //In the init(frame) and init(coder) methods you simply set the background color to fully transparent (the “clear” color). Then in drawRect() you draw the gradient on top of that transparent background, so that it blends with whatever is below.
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = .FlexibleHeight | .FlexibleWidth
        backgroundColor = UIColor.clearColor()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        autoresizingMask = .FlexibleHeight | .FlexibleWidth
        backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        //First you create two arrays that contain the “color stops” for the gradient. The first color (0, 0, 0, 0.3) is a black color that is mostly transparent. It sits at location 0 in the gradient, which represents the center of the screen because you’ll be drawing a circular gradient.
        //The second color (0, 0, 0, 0.7) is also black but much less transparent and sits at location 1, which represents the circumference of the gradient’s circle. Remember that in UIKit and also in Core Graphics, colors and opacity values don’t go from 0 to 255 but are fractional values between 0 and 1. The 0 and 1 from the locations array represent percentages: 0% and 100%, respectively.
        let components: [CGFloat] = [ 0, 0, 0, 0.3, 0, 0, 0, 0.7 ]
        let locations: [CGFloat] = [ 0, 1 ]
        //With those color stops you can create the gradient. This gives you a new CGGradient object. This is not an traditional object, so you cannot send it messages by doing gradient.methodName(). But it’s still some kind of data structure that lives in memory, and the gradient constant refers to it. (Such objects are called “opaque” types, or “handles”. They are relics from iOS frameworks that are written in the C language, such as Core Graphics.)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2)
        
        //Now that you have the gradient object, you have to figure out how big you need to draw it. The CGRectGetMidX() and CGRectGetMidY() functions return the center point of a rectangle. That rectangle is given by bounds, a CGRect object that describes the dimensions of the view.
        //If I can avoid it, I prefer not to hard-code any dimensions such as “320 by 480 points”. By asking bounds, you can use this view anywhere you want to, no matter how big a space it should fill. You can use it without problems on any screen size from the smallest iPhone to the biggest iPad.
        let x = CGRectGetMidX(bounds)
        let y = CGRectGetMidY(bounds)
        //The point constant contains the coordinates for the center point of the view and radius contains the larger of the x and y values; max() is a handy function that you can use to determine which of two values is the biggest.
        let point = CGPoint(x: x, y : y)
        let radius = max(x, y)
    
        //With all those preliminaries done, you can finally draw the thing. Core Graphics drawing always takes places in a so-called graphics context. We’re not going to worry about exactly what that is, just know that you need to obtain a reference to the current context and then you can do your drawing.
        let context = UIGraphicsGetCurrentContext()
        
        //The CGContextDrawRadialGradient() function finally draws the gradient according to your specifications.
        CGContextDrawRadialGradient(context, gradient, point, 0, point, radius,CGGradientDrawingOptions(kCGGradientDrawsAfterEndLocation))
    }
}
