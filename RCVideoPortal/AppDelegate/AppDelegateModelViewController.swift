//
//  AppDelegateModelViewController.swift
//  Glip
//
//  Created by Albert (Jinku) Gu on 07/12/2016.
//  Copyright © 2016 RingCentral. All rights reserved.
//

import UIKit

extension UIViewController {
    func topModalViewController() -> UIViewController {
        var topModalViewController = self
        var modelViewController = topModalViewController.presentedViewController

        while modelViewController != nil {
            topModalViewController = modelViewController!
            modelViewController = topModalViewController.presentedViewController
        }

        return topModalViewController
    }
}
