//
//  PolicyInstaller.swift
//  Glip
//
//  Created by QiuFeng on 2022/3/1.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import RCCommon
import UIKit

class PolicyInstaller: NSObject {
    static func install() {
        #if USE_INTUNE
            Policy.config = IntunePolicyConfig()
        #else // use default config
            Policy.config = PolicyConfig()
        #endif
    }
}
