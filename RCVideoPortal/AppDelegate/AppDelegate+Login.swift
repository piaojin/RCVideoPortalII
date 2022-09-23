//
//  AppDelegate+Login.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/11.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import ModuleManager
import RCCommon
import RingCentralCommon
import VideoImplement
import VideoInterface

final class GlipILoginViewModelDelegateImpl: GlipILoginViewModelDelegate {
    weak var delegate: GlipILoginViewModelDelegate?

    init(delegate: GlipILoginViewModelDelegate) {
        self.delegate = delegate
    }

    @objc func onLoginStatusUpdated(_ status: GlipLoginStatus, errorCodeType: GlipEErrorCodeType) {
        delegate?.onLoginStatusUpdated(status, errorCodeType: errorCodeType)
    }

    func onLogoutFailed(_ errorType: GlipEErrorCodeType) {
        delegate?.onLogoutFailed(errorType)
    }
}

extension AppDelegate: GlipILoginViewModelDelegate {
    func configRootViewController() {
        if RcCommonProfileInformation.isLoggedIn() {
            switchToMainScreen()
        } else if RcMyProfileInformation.isInProgress() {} else {
            switchToWelcomeScreen()
        }
    }

    public func isInMainScreen() -> Bool {
        if window?.rootViewController?.theClassName == "MeetingsViewController" {
            return true
        }
        return false
    }

    public func switchToMainScreen(shouldReset: Bool = false) {
        if isInMainScreen() {
            // NO need to switch again since it's already showing
            return
        }

        if let vc = ModuleManager.video?.meetingService?.createMeetingViewController() {
            let nav = RCUIPopGestureNavigationController(rootViewController: vc)
            window?.switchRootViewController(nav)
            MultitaskManager.shared.bringMultitaskViewToFrontIfNeeded()
            rootViewController = nav
        }
    }

    public func switchToWelcomeScreen() {
        let welcomeVC = WelcomeViewController()
        let nav = RCUIPopGestureNavigationController(rootViewController: welcomeVC)
        window?.switchRootViewController(nav)
        rootViewController = nav
    }

    func appLaunchViaURLSchemeWithRCAuthCode(_ code: String, state: String?, showLoading: Bool = true, externDiscoveryURI: String = "", tokenURI: String = "") {
        // EXPECTED SCENARIO: SIGN VIA RC SSO -> choose Gmail -> external Safari -> jump back to Glip with glip://rclogin?code=xxx
        DLOG(LogTagConstant.kLoginTag, message: "login in with auth code...")
        if RcCommonProfileInformation.isLoggedIn() {
            DLOG(LogTagConstant.kLoginTag, message: "loggedIn status")
            return
        }

        if ModuleManager.video?.meetingService?.isActiveMeetingInProgress() == true || ModuleManager.video?.meetingService?.isJAHOrWRInProgress() == true {
            DLOG(LogTagConstant.kLoginTag, message: "Active Meeting In Progress, or JAH, or waiting room...")
            GlipUIAlertUtility.displayAlertOfText("On video call".localized(), text: "Sorry, you are currently on a video call. Try again after the call ends.".localized(), actionText: "OK".localized())
            return
        }

        // Common case
        let account = loginUiController?.getLoginViewModel()?.getAccount()
        account?.resetValue()
        account?.setLoginType(.viaRcAuthCode)
        account?.setExternDiscoveryUrl(externDiscoveryURI)
        account?.setTokenUrl(tokenURI)
        account?.setRCAuthCode(code)
        if state != nil && state != "" {
            account?.setState(state!)
        }

        loginUiController?.getLoginViewModel()?.setAccount(account)
        loginUiController?.login()

        if showLoading {
            RootController.shared.showPleaseWaitLoading(view: AppDelegate.shared().window)
        }
    }

    func onLoginStatusUpdated(_ status: GlipLoginStatus, errorCodeType: GlipEErrorCodeType) {
        var alertTitle: String = "Sign In Failed".localized()
        RcProgressHUD.shared.dismissWithAnimated(false)

        if errorCodeType != .NOERRORCODE && errorCodeType != .NOTAUTHORIZED && errorCodeType != .FORCELOGOUT {
            if errorCodeType == GlipEErrorCodeType.INVALIDLOGIN || errorCodeType == GlipEErrorCodeType.INVALIDCREDENTIALS {
                let okAction = RCUIAlertAction(title: "OK".localized(), style: .default, handler: nil)
                GlipUIAlertUtility.displayAlertOfActions(alertTitle, text: "Oops, the link you are trying to use has expired. Please enter your credentials and try again.".localized(), actions: [okAction])
            } else if errorCodeType == GlipEErrorCodeType.NETWORKNOTAVAILABLE {
                // show offline indicator
                GlipUIAlertUtility.displayNoNetworkAlert()
            } else if errorCodeType == .REAUTHORIZE || errorCodeType == .LOGINREAUTHORIZE {
                showReAuthorizeAlert()
            } else if errorCodeType == .RCACCOUNTEXTENSIONMISMATCH || errorCodeType == .RCACCOUNTMISMATCH {
                GlipUIAlertUtility.displaySignInUnsuccessfulHint(contactSupportAction: {
                    self.switchToContactSupport()
                }, closeAction: nil)
            } else if errorCodeType == .RCACCOUNTACCESSRESTRICTION
                || errorCodeType == .REQUESTTIMEOUT
                || errorCodeType == .RCNOGLIPPERMISSION {
                if let text = AppDelegate.alertTextForError(errorCodeType) {
                    GlipUIAlertUtility.displayAlertOfText(errorCodeType == .RCACCOUNTACCESSRESTRICTION ? nil : alertTitle, text: text, actionText: "OK".localized())
                }
            } else {
                var message: String = ""
                if errorCodeType == GlipEErrorCodeType.UNKNOWNERROR || errorCodeType == GlipEErrorCodeType.INVALIDCREDENTIALS {
                    message = "Oops, we are having trouble signing you in. If the problem persists, contact our customer support team.".localized()
                } else if errorCodeType == GlipEErrorCodeType.ACCOUNTLOCKED {
                    message = "Your account has been locked. Please contact your company's admin for %@ or contact customer support.".localized(arguments: Target.type.brandName)
                    alertTitle = "Account Locked".localized()
                }

                let contactAction = RCUIAlertAction(title: "Contact Support".localized(), style: UIAlertAction.Style.default) { (action: RCUIAlertAction) -> Void in
                    if let url = URL(string: Target.type.contactSupportUrl) {
                        let title = "Contact Support".localized()
                        Navigator.openWithSafari(url: url, title: title, openInApp: true)
                    }
                }

                let closeAction = RCUIAlertAction(title: "Close".localized(), style: UIAlertAction.Style.cancel, handler: nil)

                GlipUIAlertUtility.displayAlertOfActions(alertTitle, text: message, actions: [closeAction, contactAction])
                ImageManagerConfiguration.shared.removeImageMangersWhenLogout()
            }
        }
        if errorCodeType != .NOERRORCODE {
            if let rootVC = self.window?.rootViewController as? RCUIPopGestureNavigationController {
                if let unifiedLoginVC = rootVC.topViewController as? LoginViewController {
                    unifiedLoginVC.reloadWeb()
                }
            }
        }

        if status == .loggedIn {
            loadDynamicResources()
            switchToMainScreen()
        }

        if status == .notLoggedIn {}
    }

    func onLogoutFailed(_ errorType: GlipEErrorCodeType) {
        DLOG(LogTagConstant.kApplicationTag, message: "errorType is:\(errorType)")
        RcProgressHUD.shared.dismissWithAnimated(false)
        if errorType == .NETWORKNOTAVAILABLE {
            GlipUIAlertUtility.displayAlertOfText("No Internet Connection".localized(), text: "Check your network connection and try again.".localized(), actionText: "OK".localized())
        } else {
            GlipUIAlertUtility.displayAlertOfText("Sign Out Failed".localized(), text: "We're having trouble signing out the account, please check your network connection and try again.".localized(), actionText: "OK".localized())
        }
    }

    func switchToContactSupport() {
        if let rootVC = window?.rootViewController as? RCUIPopGestureNavigationController {
            let vc = GlipWebViewController()
            vc.url = URL(string: Target.type.contactSupportUrl)
            vc.title = "Contact Support".localized()
            rootVC.pushViewController(vc, animated: true)
        }
    }

    func showReAuthorizeAlert() {
        showReAuthorizeAlert(appName: Target.type.brandName)
    }

    func showReAuthorizeAlert(appName: String) {
        let okAction = RCUIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default) { (action: RCUIAlertAction) -> Void in
        }

        let alertTitle = "Sign In with %@ Is Required".localized(arguments: appName)
        let message = "Please sign in with %@ to continue.".localized(arguments: appName)
        GlipUIAlertUtility.displayAlertOfActions(alertTitle, text: message, actions: [okAction])
    }

    func logout(withIsResetPassword resetPassword: Bool = false, withDeleteAccount deleteAcccount: Bool = false) {
        if RcCommonProfileInformation.isLoggedIn() {
            if CallKitController.shared.callStatus == .calling, !(ModuleManager.video?.roomsService?.isControlingRoomsHost() ?? false) {
                if resetPassword {
                    DLOG(LogTagConstant.kApplicationTag, message: "dismiss progress for reset pwd case")
                    RcProgressHUD.shared.dismissWithAnimated(false)
                }
                MultitaskForbiddenAlert.current.show()
                return
            }
            if !resetPassword {
                if let window = AppDelegate.shared().window {
                    RcProgressHUD.shared.showInView(window, status: "Please wait...".localized())
                }
            }
            DLOG(LogTagConstant.kApplicationTag, message: "logout by reset password? \(resetPassword)")
            var logoutType: GlipLogoutType = resetPassword ? .viaResetPassword : .viaSignOut
            if deleteAcccount {
                logoutType = .viaAccountDeletion
            }
            loginUiController?.logout(logoutType)
            ImageManagerConfiguration.shared.removeImageMangersWhenLogout()
        }
    }

    static func alertTextForError(_ errorCodeType: GlipEErrorCodeType) -> String? {
        if errorCodeType == .REQUESTTIMEOUT {
            return "We are having trouble signing you in. We suggest checking your network and trying again.".localized()
        } else if errorCodeType == .RCNOGLIPPERMISSION {
            return "%@ is not currently enabled in your %@ service plan. Please contact your account administrator.".localized(arguments: Target.type.appName, Target.type.shortAppName)
        } else if errorCodeType == .RCACCOUNTACCESSRESTRICTION {
            return "You have been logged out in accordance with the IT policy of your company. Please re-login with the company sanctioned account. Please contact your IT administrator if this is in error.".localized()
        }

        return nil
    }
}
