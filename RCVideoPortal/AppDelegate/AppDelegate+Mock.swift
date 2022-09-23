//
//  AppDelegate+Mock.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/14.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import DebugInterface
import Foundation
import ModuleManager
import ModuleRouter
import PhoneInterface
import RCCommon
import SettingInterface
import UIKit

// MARK: Mock Router

extension AppDelegate {
    func setUpMockRouter() {
        ModuleRouter.Router.shared.register(path: RoutePath.openSettingPath,
                                            handler: MockOpenSettingRouteHandler())

        ModuleRouter.Router.shared.register(path: RoutePath.openDebugTable,
                                            handler: MockDebugTableRouteHandler())
    }
}

// MARK: Mock Modules

extension AppDelegate {
    func setUpMockModules() {
        // Mock Phone
        ModuleManager.shared.registerModule(name: PhoneModuleName, moduleClass: NSClassFromString(MockPhoneModuleClass) as! BaseModule.Type)
        ModuleManager.shared.addModule(name: PhoneModuleName)
    }
}

// MARK: Mock Settings Router

private final class MockOpenSettingRouteHandler: RouteHandler {
    override func onHandle(context: RouteContext, nextBlock: RouteNextBlock, completeBlock: @escaping RouteCompleteBlock) {
        let signOutAction = RCUIAlertAction(title: "Sign Out".localized(), style: .default) { _ in
            AppDelegate.shared().logout()
        }

        let debugAction = RCUIAlertAction(title: "Enter Debug".localized(), style: .default) { _ in
            if let rootVC = RootController.shared.window?.rootViewController {
                ModuleRouter.Router.shared.open(path: RoutePath.openDebugTable, source: rootVC)
            } else {
                DLOG(LogTagConstant.kLogTag, message: "rootViewController is nil")
            }
        }

        let themesAction = RCUIAlertAction(title: "Themes".localized(), style: .default) { _ in
            AppDelegate.shared().showThemesViewController()
        }

        let cancelAction = RCUIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)

        _ = RCUIAlertManager.sharedInstance.showAlertOfTitle("My Profile", text: "", style: .actionSheet, actions: [signOutAction, debugAction, themesAction, cancelAction], viewController: RootController.shared.modalViewController(on: RootController.shared.window), additionObject: nil, completion: nil)

        completeBlock()
    }
}

// MARK: Mock Debug Router

private final class MockDebugTableRouteHandler: RouteHandler {
    override func onHandle(context: RouteContext, nextBlock: () -> Void, completeBlock: @escaping () -> Void) {
        let debugVC = DebugTableViewController()
        let sourceViewController = context.source ?? UIApplication.topViewController()
        let sourceNav: UINavigationController? = sourceViewController is RCUIPopGestureNavigationController ? (sourceViewController as? RCUIPopGestureNavigationController) : sourceViewController?.navigationController
        sourceNav?.pushViewController(debugVC, animated: true)
        completeBlock()
    }
}
