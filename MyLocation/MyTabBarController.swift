//
//  MyTabBarController.swift
//  MyLocation
//
//  Created by Максим on 10.03.16.
//  Copyright © 2016 Maxim. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}
