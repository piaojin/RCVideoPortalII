//
//  RingCentralTargetConfig.swift
//  changeColorTheme
//
//  Created by Morty Zheng on 2021/2/18.
//

import Mediator
import PAL
import RCCommon
import RingCentralCommon
import RingCentralCore

class RingCentralTargetConfig: TargetConfig {
    override var isRingCentral: Bool {
        return true
    }

    override var googleServices: [String: String] {
        return [
            "com.glip.mobile": "GoogleService-Info",
            "com.glip.mobile.rc": "GoogleService-Info-inhouse",
        ]
    }

    override var applicationTarget: GlipXApplicationTarget {
        return .RINGCENTRALAPP
    }

    override var shareFilterMessageName: String {
        return "%@ Message".localized(arguments: Target.type.appName)
    }

    override var metricCollectAgentDelegate: MetricCollectDelegate? {
//        #if RCVideoPortal_TARGET
//            return FirebasePerformanceMetricCollect()
//        #else
//            return nil
//        #endif
        return nil
    }

    override var bugReporterAgentDelegate: BugReportDelegate? {
//        #if RCVideoPortal_TARGET
//            return FirebaseCrashlyticsReporter()
//        #else
//            return nil
//        #endif
        return nil
    }

    override class func rcvFeedbackRecipient() -> String {
        return Target.type.rcvFeedbackRecipient
    }

    override var allowShowProTipInInviteAnyonePage: Bool {
        if RcPermissionUtil.isRcFeaturePermissionEnabled(.SMSSEND) {
            return true
        } else {
            return NativeSMSManager.shared.hasNativeSmsPermission()
        }
    }

    override func getShareText() -> String {
        var name = RcCommonProfileInformation.getFirstName()
        if name.isEmpty || name == "" {
            name = RcCommonProfileInformation.getUserDisplayName()
        }
        let inviteLink = RcCommonProfileInformation.getGlipInviteUrl()
        return "%@ invites you to create a free RingCentral account with unlimited video meetings and messaging: %@".localized(arguments: name, inviteLink)
    }

    override var desktopPageBrandImageName: String {
        if RcAccountUtils.isPhoenixAccount() {
            return "logo_phoenix"
        } else {
            return "img_pt_logo"
        }
    }

    override var startScreenCreateAccountTitle: String {
        return "Create free account".localized()
    }

    override var desktopPageMainImageName: String {
        return "img_desktop_app_main_rc"
    }

    override var desktopPageMainImage: UIImage? {
        UIImage(named: "img_desktop_app_main_rc")
    }

    override func supportedLanguageList() -> [String] {
        let brandId = RcCommonProfileInformation.getRcBrandType()
        if let codeConfig = Target.codeConfigWithBrandId(brandId: brandId) {
            return codeConfig.supportedLanguageList()
        }

        return TargetConfig.fullLanguageList
    }

    override func defaultLanguage() -> String {
        let brandId = RcCommonProfileInformation.getRcBrandType()
        if let codeConfig = Target.codeConfigWithBrandId(brandId: brandId) {
            return codeConfig.defaultLanguage()
        }

        return TargetConfig.defaultLanguage
    }

    override func shouldUseAlterTheme() -> Bool {
        if RcAccountUtils.isPhoenixAccount() {
            return true
        } else {
            return false
        }
    }

    override var universalLinkHost: RoutingType {
        return .baseURL([
            "*.glip.com",
            "*.glip.net",
            "*.glipdemo.com",
            "*.ringcentral.com",
            "glipdemo.com",
            "app-xmnup.asialab.glip.net",
            "develop.fiji.gliprc.com",
            "app-telus.uat.ringcentral.com",
            "app.businessconnect.telus.com",
            "app.ringcentral.biz",
        ])
    }

    override func sendFeedbackAction(vc: FeedbackAble) {
        vc.sendRCFeedback()
    }

    override var meetingsLinkPrefixList: [String] {
        return [
            "https://rcm.rcdev.ringcentral.com/j/",
            "https://webinar.ringcentral.com/",
            "https://stagerc.meetzoom.us",
            "https://meetings.ringcentral.com/j/",
            "https://ringcentral.zoom.us/j/",
            "https://rcdev.dev.meetzoom.us/j/",
            "https://rcm.stage.ringcentral.com/j/",
            "https://rcm.ops.ringcentral.com/j/",
        ]
    }

    override var joinMeetingsUrlSchemePrefix: String {
        return "zoomrc://meetings.ringcentral.com/join?confno="
    }

    override var meetingAppUrlScheme: String {
        return "zoomrc://"
    }

    override var meetingAppStoreUrl: String {
        return "https://itunes.apple.com/app/ringcentral-meetings/id688920955"
    }

    override var meetingLink: [String] {
        #if APPSTORE
            return [ // RCV
                "v.ringcentral.com",
                "*.video.ringcentral.biz",
                "*.video.ringcentral.com",
                // RCM
                "meetings.ringcentral.com",
                "ringcentral.zoom.us",
                "*.dev.meetzoom.us",
                "stagerc.meetzoom.us",
                "ops.rc.zoom.us",
                "rcm.rcdev.ringcentral.com",
                "rcm.stage.ringcentral.com",
                "rcm.ops.ringcentral.com",
            ]
        #else
            return [ // RCV
                "v.ringcentral.com",
                "*.lab.nordigy.ru",
                "*.video.ringcentral.biz",
                "*.video.ringcentral.com",
                // RCM
                "meetings.ringcentral.com",
                "ringcentral.zoom.us",
                "*.dev.meetzoom.us",
                "stagerc.meetzoom.us",
                "ops.rc.zoom.us",
                "rcm.rcdev.ringcentral.com",
                "rcm.stage.ringcentral.com",
                "rcm.ops.ringcentral.com",
            ]

        #endif
    }

    override func getCanJoinMeetingBrands(with meetingType: MeetingType) -> [String] {
        return getCanJoinMeetingBrands(with: meetingType, isGlipInstance: true, isDynamic: true)
    }

    static let config = RingCentralTargetConfig()
}
