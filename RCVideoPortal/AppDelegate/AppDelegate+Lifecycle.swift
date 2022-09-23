//
//  AppDelegate+Lifecycle.swift
//  RCVideoPortal
//
//  Created by rcadmin on 2022/7/28.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import ModuleManager
import RCCommon
import RingCentralHome

extension AppDelegate: GlipILifecyleViewModelDelegate {
    func onStatusUpdated(_ status: GlipLoginStatus, errorCode: GlipEErrorCodeType) {
        // add dispatch to mainQ because background change password force to logout.
        DispatchQueue.main.async(execute: {
            DLOG(LogTagConstant.kApplicationTag, message: "satus: \(status.rawValue)")
            DLOG(LogTagConstant.kApplicationTag, message: "errorCode: \(errorCode.rawValue)")

            switch status {
            case .loggedIn, .loggedInRcOnly:
                // close spinner for drp logged in;

                RcProgressHUD.shared.dismissWithAnimated(false)
                GlobalPrinter.shared.isLogEnabled = RcCommonProfileInformation.isLoggingEnabled()

                DLOG(LogTagConstant.kApplicationTag, message: "handle login start.")

                self.configRootViewController()
            case .inProgress:
                self.configRootViewController()
            case .notLoggedIn:
                if Target.type.useZoomSdk {
                    ModuleManager.video?.meetingService?.logoutZoomSDK()
                }

                if errorCode == GlipEErrorCodeType.FORCELOGOUT
                    || errorCode == GlipEErrorCodeType.NOTAUTHORIZED
                    || errorCode == GlipEErrorCodeType.RCACCOUNTACCESSRESTRICTION {
                    TargetConfigManager.manager.logoutCode = errorCode
                    self.loadDynamicResources()

                    var text = "You have been signed out. Sign in again.".localized()
                    if let alertText = AppDelegate.alertTextForError(errorCode) {
                        text = alertText
                    }
                    let title: String? = (errorCode == GlipEErrorCodeType.RCACCOUNTACCESSRESTRICTION) ? nil : "Signed Out".localized()
                    GlipUIAlertUtility.displayAlertOfActionsOnMainWindow(title, text: text, actions: [RCUIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: nil)])
                    ModuleManager.video?.meetingService?.setZoomDefaultSettings()
                    // It will clear any traits or userId's cached on the device
                    // Analysis.flushAndReset()
                } else if errorCode == GlipEErrorCodeType.NOERRORCODE || errorCode == GlipEErrorCodeType.LOGOUT || errorCode == GlipEErrorCodeType.LOGOUTANDRESETPASSWORD || errorCode == GlipEErrorCodeType.ACCOUNTDELETION {
                    ModuleManager.video?.meetingService?.setZoomDefaultSettings()
                    self.configRootViewController()
                } else if errorCode == .REAUTHORIZE {
                    self.configRootViewController()
                    self.showReAuthorizeAlert()
                }

                NotificationCenter.default.post(name: NSNotification.Name.AppDidLogout, object: nil, userInfo: nil)
            @unknown default:
                break
            }
        })
    }

    func onPerformDrpStatusUpdated(_ status: GlipDrpStatus) {}

    func onRcFeaturePermissonChanged(_ featurePermission: GlipRcServiceFeaturePermission, isEnabled: Bool) {
        if featurePermission == .EMBEDDEDFLAG {
            NotificationCenter.default.post(name: Notification.Name.VideoServicePermissionChanges, object: nil)
        }
    }

    func onMobileAssetsUpdate(_ path: String) {}

    func onMobileVideoConfigAssetsUpdate(_ path: String) {}

    func onAppForceUpgradeReceived() {}

    func onAppSoftUpgradeReceived(_ version: String) {}

    func onReconnectGlipStatusUpdated(_ status: GlipReconnectGlipStatus) {}

    func onForceUpdateIncomingCallAnswer(inRc answerInRc: Bool) {}

    func onPromptForceLogout(_ grantGlipPermission: Bool) {}

    func onCallerIdInfoArrived() {}

    func onShowE911Alert() {}

    func onFeatureManagerInitFinished(_ success: Bool) {}

    func onZoomLogout() {}

    func onDeviceTokenInvalid() {}

    func onDigitalLineAssigned() {}

    func onPhoenixAccountUpgrade() {}

    func onTabOrderChanged() {}

    func onPrimaryCalendarsConnected(_ success: Bool) {}

    func onMedalliaSurveyShowedTimeChanged(_ medalliaSurveyShowedTime: Int64) {}
}
