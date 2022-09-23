//
//  ThemeType.swift
//  Glip
//
//  Created by Jesse Xie on 2020/9/4.
//  Copyright © 2020 RingCentral. All rights reserved.
//

import RCCommon
enum LightDarkAppearanceType: Int {
    case followSystem = 0
    case light = 1
    case dark = 2

    var name: String {
        switch self {
        case .followSystem:
            return "System default".localized()
        case .light:
            return "Light".localized()
        case .dark:
            return "Dark".localized()
        }
    }

    var dataTrackingName: String {
        switch self {
        case .followSystem:
            return "System default"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .followSystem:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

extension KeyCenter {
    /* Light/Dark Appearance Theme */
    static let kAppearanceThemeTypeKey: String = "kThemeTypeKey"
}
