//
//  RcMyProfileInformation.swift
//  Glip
//
//  Created by Edgar Yang on 2020/12/10.
//  Copyright © 2020 RingCentral. All rights reserved.
//

import Foundation
import RCCommon
import RingCentralCore

protocol GlipMyProfileInformationProtocol: AnyObject {
    static func canResetPassword() -> Bool
    static func hasVideoService() -> Bool
    static func hasEditExtensionInfoPermission() -> Bool
    static func hasPersonalContactsPermission() -> Bool
    static func shouldShowDesktopAppEntry() -> Bool
    static func isNeedToDisplayCompanyContactExplanatory() -> Bool
    static func isOfficeUser() -> Bool
    static func setNeedToEnterWelcomeScreen(_ state: Bool)
    static func isNeedToEnterWelcomeScreen() -> Bool
    static func isIncomingCallBlocked() -> Bool

    static func isNeedToDisplayGuestsContactExplanatory() -> Bool

    static func isInProgress() -> Bool

    static func isInvitePeopleComplete() -> Bool

    static func setInvitePeopleComplete(_ complete: Bool)

    static func isEnabledTelephonyMobileBadges() -> Bool

    static func isShowNewMessageBadgesSetting() -> Bool

    // static func disableChinaRegionAppTelephony(_ disable: Bool)

    static func abbreviationString(_ name: String) -> String

    static func isRCCompanyDomain(_ email: String) -> Bool

    static func setNeedToDisplayCompanyContactExplanatory(_ setted: Bool)

    static func setNeedToDisplayGuestsContactExplanatory(_ setted: Bool)

    static func isAllowUninvitedEmployeesToJoin() -> Bool

    static func isRcvService() -> Bool

    static func isEnableGenNewJoinUrl() -> Bool

    static func shouldShowSettingsTab() -> Bool

    static func isClientBadgeCalculationDisabled() -> Bool
}

extension GlipMyProfileInformation: GlipMyProfileInformationProtocol {}

class RcMyProfileInformation: GlipMyProfileInformationProtocol {
    static var profileInformationType: GlipMyProfileInformationProtocol.Type = GlipMyProfileInformation.self

    static func isInProgress() -> Bool {
        return profileInformationType.isInProgress()
    }

    static func isInvitePeopleComplete() -> Bool {
        return profileInformationType.isInvitePeopleComplete()
    }

    static func setInvitePeopleComplete(_ complete: Bool) {
        profileInformationType.setInvitePeopleComplete(complete)
    }

    static func isEnabledTelephonyMobileBadges() -> Bool {
        return profileInformationType.isEnabledTelephonyMobileBadges()
    }

    static func isShowNewMessageBadgesSetting() -> Bool {
        return profileInformationType.isShowNewMessageBadgesSetting()
    }

    // static func disableChinaRegionAppTelephony(_ disable: Bool) {
    //     return profileInformationType.disableChinaRegionAppTelephony(disable)
    // }

    static func abbreviationString(_ name: String) -> String {
        return profileInformationType.abbreviationString(name)
    }

    static func isRCCompanyDomain(_ email: String) -> Bool {
        return profileInformationType.isRCCompanyDomain(email)
    }

    static func setNeedToDisplayCompanyContactExplanatory(_ setted: Bool) {
        return profileInformationType.setNeedToDisplayCompanyContactExplanatory(setted)
    }

    static func setNeedToDisplayGuestsContactExplanatory(_ setted: Bool) {
        return profileInformationType.setNeedToDisplayGuestsContactExplanatory(setted)
    }

    static func isAllowUninvitedEmployeesToJoin() -> Bool {
        return profileInformationType.isAllowUninvitedEmployeesToJoin()
    }

    static func isRcvService() -> Bool {
        return profileInformationType.isRcvService()
    }

    static func isEnableGenNewJoinUrl() -> Bool {
        return profileInformationType.isEnableGenNewJoinUrl()
    }

    static func shouldShowSettingsTab() -> Bool {
        return profileInformationType.shouldShowSettingsTab()
    }

    static func isClientBadgeCalculationDisabled() -> Bool {
        return profileInformationType.isClientBadgeCalculationDisabled()
    }

    static func canResetPassword() -> Bool {
        return profileInformationType.canResetPassword()
    }

    static func hasVideoService() -> Bool {
        return profileInformationType.hasVideoService()
    }

    static func hasPersonalContactsPermission() -> Bool {
        return profileInformationType.hasPersonalContactsPermission()
    }

    static func hasEditExtensionInfoPermission() -> Bool {
        return profileInformationType.hasEditExtensionInfoPermission()
    }

    static func shouldShowDesktopAppEntry() -> Bool {
        return profileInformationType.shouldShowDesktopAppEntry()
    }

    static func isNeedToDisplayCompanyContactExplanatory() -> Bool {
        return profileInformationType.isNeedToDisplayCompanyContactExplanatory()
    }

    static func isOfficeUser() -> Bool {
        return profileInformationType.isOfficeUser()
    }

    static func setNeedToEnterWelcomeScreen(_ state: Bool) {
        profileInformationType.setNeedToEnterWelcomeScreen(state)
    }

    static func isNeedToEnterWelcomeScreen() -> Bool {
        return profileInformationType.isNeedToEnterWelcomeScreen()
    }

    static func isJoinNowNotificationEnabled() -> Bool {
        let controller = CommonCoreLibFactory.createJoinNowSettingsUiController(nil)
        let needToAlert = controller?.needToAlert() ?? false
        return RcCommonProfileInformation.isJoinNowEnabled() && needToAlert
    }

    static func isIncomingCallBlocked() -> Bool {
        return profileInformationType.isIncomingCallBlocked()
    }

    static func isNeedToDisplayGuestsContactExplanatory() -> Bool {
        return profileInformationType.isNeedToDisplayGuestsContactExplanatory()
    }
}
