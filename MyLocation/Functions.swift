//
//  Functions.swift
//  MyLocation
//
//  Created by Максим on 03.03.16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import Foundation

func afterDelay(seconds: Double, compleatAction: ()->() ){
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    
    dispatch_after(when, dispatch_get_main_queue(), compleatAction)
}