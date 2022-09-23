//
//  AppDelegate+Appearance.swift
//  Glip
//
//  Created by Jesse Xie on 2020/9/11.
//  Copyright © 2020 RingCentral. All rights reserved.
//

import Foundation
import RCCommon

extension AppDelegate {
    func registerNewWindowNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateNewWindowTheme(_:)), name: UIWindow.didBecomeVisibleNotification, object: nil)
    }

    @objc func updateNewWindowTheme(_ notification: Notification) {
        if let window = notification.object as? UIWindow {
            // TODO: white list to avoid set appearance for 3rd party windows
            DLOG(LogTagConstant.kDarkmodeTag, message: "will updateAppearance after observering new window: \(window)")
            updateAppearance(window)
        }
    }

    func updateAppearance(_ window: UIWindow? = UIApplication.shared.windows.first) {
        if #available(iOS 13.0, *) {
            let currentTypeRawValue = UserDefaults.standard.integer(forKey: KeyCenter.kAppearanceThemeTypeKey)
            DLOG(LogTagConstant.kDarkmodeTag, message: "currentTypeRawValue :\(currentTypeRawValue);\n window: \(String(describing: window));\n 1st window: \(String(describing: UIApplication.shared.windows.first ?? nil));\n key window: \(String(describing: UIApplication.shared.keyWindow ?? nil));\n windows: \(UIApplication.shared.windows)")
            if let lightDarkAppearance = LightDarkAppearanceType(rawValue: currentTypeRawValue) {
                updateAppearance(lightDarkAppearance, window: window)
            }
        }
    }

    func updateAppearance(_ theme: LightDarkAppearanceType, window: UIWindow?) {
        if #available(iOS 13.0, *) {
            switch theme {
            case .light:
                window?.overrideUserInterfaceStyle = .light
            case .dark:
                window?.overrideUserInterfaceStyle = .dark
            default:
                window?.overrideUserInterfaceStyle = .unspecified
            }
        }
    }

    func tryUpdateTheme() {
        if #available(iOS 13.0, *) {
            /* MTR-43331, app was forced logout because sandbox's file was protected by iOS, so theme was default when app was launched w/o 1st unlock, e.g reboot device, invoke by VoIP push */
            DLOG(LogTagConstant.kDarkmodeTag, message: "give one more chance to update first window theme")
            if let firstWindow = UIApplication.shared.windows.first {
                DLOG(LogTagConstant.kDarkmodeTag, message: "firstWindow overrideUserInterfaceStyle: \(firstWindow.overrideUserInterfaceStyle.rawValue)")
                let currentTypeRawValue = UserDefaults.standard.integer(forKey: KeyCenter.kAppearanceThemeTypeKey)
                if currentTypeRawValue != firstWindow.overrideUserInterfaceStyle.rawValue, let theme = LightDarkAppearanceType(rawValue: currentTypeRawValue) {
                    DLOG(LogTagConstant.kDarkmodeTag, message: "first window: \(firstWindow), currentTypeRawValue :\(currentTypeRawValue)")
                    updateAppearance(theme, window: firstWindow)
                }
            }
        }
    }

    func resetAppearance() {
        UserDefaults.standard.set(LightDarkAppearanceType.followSystem.rawValue, forKey: KeyCenter.kAppearanceThemeTypeKey)
        DLOG(LogTagConstant.kDarkmodeTag, message: "will updateAppearance from resetAppearance")
        updateAppearance()
    }

    func showThemesViewController() {
        let types: [LightDarkAppearanceType] = [.followSystem, .light, .dark]
        let typeList = types.map { $0.name }

        let pickerVC = PickerTableViewController.picker("Themes".localized(), datasource: typeList) { t in
            _ = t
        }
        pickerVC.didSelectedBlock = { index in
            guard index.row < types.count else { return }
            let selectType = types[index.row]
            let currentTypeRawValue = UserDefaults.standard.integer(forKey: KeyCenter.kAppearanceThemeTypeKey)
            if currentTypeRawValue != selectType.rawValue {
                UserDefaults.standard.set(selectType.rawValue, forKey: KeyCenter.kAppearanceThemeTypeKey)
                for window in UIApplication.shared.windows {
                    AppDelegate.shared().updateAppearance(window)
                }
            }
        }
        let currentTypeRawValue = UserDefaults.standard.integer(forKey: KeyCenter.kAppearanceThemeTypeKey)
        if let currentType = LightDarkAppearanceType(rawValue: currentTypeRawValue) {
            pickerVC.selection = types.firstIndex(of: currentType) ?? 0
        }

        let topVC = UIApplication.topViewController()
        let topNav: UINavigationController? = topVC is RCUIPopGestureNavigationController ? (topVC as? RCUIPopGestureNavigationController) : topVC?.navigationController
        topNav?.pushViewController(pickerVC, animated: true)
    }
}

@available(iOS 13.0, *)
class WindowTraitCollection {
    static let current = WindowTraitCollection()
    var userInterfaceStyle: UIUserInterfaceStyle = .unspecified
}
