//
//  TargetInstaller.swift
//  Glip
//
//  Created by Jayden Liu on 2021/11/18.
//  Copyright © 2021 RingCentral. All rights reserved.
//

import Foundation
import RCCommon

class TargetInstaller {
    static func install() {
        #if USE_DIMELO
            TargetConfig.useDimelo = true
        #else
            TargetConfig.useDimelo = false
        #endif

        Target.basePath = "Glip"
        Target.type = RingCentralTargetConfig.config
        Target.clazz = RingCentralTargetConfig.self

        BrandInfo.defaultConfig = RingCentralTargetConfig.config

        // the dynamicJson file has meeting key, these config meetings may require splice meeting links.
        TargetConfig.specialBrandConfigs = [
            RingCentralTargetConfig.config,
        ]

        Target.isTargetInitilized = true
    }
}
