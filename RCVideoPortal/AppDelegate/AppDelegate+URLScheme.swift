//
//  AppDelegate+URLScheme.swift
//  Glip
//
//  Created by Jacob on 12/28/16.
//  Copyright © 2016 RingCentral. All rights reserved.
//

import ProgressHUD
import RCCommon
import RingCentralCore

extension AppDelegate {
    // MARK: Launch from URI

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if RcCommonProfileInformation.isLoggedIn(), RcCommonProfileInformation.isLoggedInRcOnlyMode() {
            GlipUIAlertUtility.displayAlertOfText("%@ Error".localized(arguments: Target.type.appName), text: "Sorry, %@ is experiencing an issue. Try again later.".localized(arguments: Target.type.appName), actionText: "OK".localized())
            return false
        }

        if BlockingAlertManager.shared.hasBlockingAlert() {
            return false
        }

        if CallKitController.shared.callStatus == .calling && !MultitaskManager.shared.isReady {
            GlipUIAlertUtility.displayAlertOfText("Meeting In Progress".localized(), text: "Sorry, you are currently waiting for the host. Please try again after leave the meeting.".localized(), actionText: "OK".localized())
            return false
        }

        if url.absoluteString.hasPrefix("glip://rclogin?"), let params = parserUrlParams(url: url) {
            guard let code = params["code"] else {
                return false
            }
            appLaunchViaURLSchemeWithRCAuthCode(code, state: params["state"], showLoading: true, externDiscoveryURI: params["discovery_uri"] ?? "", tokenURI: params["token_uri"] ?? "")
        }

        return true
    }

    func parserUrlParams(url: URL) -> [String: String]? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
        }
    }
}
