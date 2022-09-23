//
//  CallWindowRootViewController.swift
//  Glip
//
//  Created by John Wu on 2/24/17.
//  Copyright © 2017 RingCentral. All rights reserved.
//

import RCCommon
import UIKit

class CallWindowRootViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        }
        return Target.type.getPreferredStatusBarStyle()
    }
}
