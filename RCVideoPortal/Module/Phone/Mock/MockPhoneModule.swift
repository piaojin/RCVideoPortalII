//
//  MockPhoneModule.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import ModuleManager
import PhoneInterface

public let MockPhoneModuleClass = "RCVideoPortal.MockPhoneModule"

public class MockPhoneModule: BaseModule, PhoneModuleProtocol {
    public static func initCoreLib() {}

    public override func onLoad() {
        serviceManager.register(TelephonyServiceProtocol.self, implClass: MockTelephonyService.self)
        serviceManager.register(InformationServiceProtocol.self, implClass: MockInformationService.self)
        serviceManager.register(PageServiceProtocol.self, implClass: MockPageService.self)
        serviceManager.register(SiriAudioCallServiceProtocol.self, implClass: MockSiriAudioCallService.self)
        serviceManager.register(VoiceMailServiceProtocol.self, implClass: MockVoiceMailService.self)
        serviceManager.register(SettingServiceProtocol.self, implClass: MockPhoneSettingService.self)
        serviceManager.register(SMBServiceProtocol.self, implClass: MockSMBService.self)
        serviceManager.register(PhoneMiscServiceProtocol.self, implClass: MockPhoneMiscService.self)
        serviceManager.register(InviteServiceProtocol.self, implClass: MockInviteService.self)

        registForbiddenEvent()

        // Add notification factory

        // Routes
        registerRoutes()

        // Settings
        registerSettings()

        // Banner

        // Other
        setupPhoneNumberFetcherForFeedbackUtil()
    }

    public var smbService: SMBServiceProtocol? {
        serviceManager.get(SMBServiceProtocol.self)
    }

    public var telephonyService: TelephonyServiceProtocol? {
        serviceManager.get(TelephonyServiceProtocol.self)
    }

    public var informationService: InformationServiceProtocol? {
        serviceManager.get(InformationServiceProtocol.self)
    }

    public var pageService: PageServiceProtocol? {
        serviceManager.get(PageServiceProtocol.self)
    }

    public var siriAudioCallService: SiriAudioCallServiceProtocol? {
        serviceManager.get(SiriAudioCallServiceProtocol.self)
    }

    public var voiceMailService: VoiceMailServiceProtocol? {
        serviceManager.get(VoiceMailServiceProtocol.self)
    }

    public var settingService: SettingServiceProtocol? {
        serviceManager.get(SettingServiceProtocol.self)
    }

    public var miscService: PhoneMiscServiceProtocol? {
        serviceManager.get(PhoneMiscServiceProtocol.self)
    }

    public var inviteService: InviteServiceProtocol? {
        serviceManager.get(InviteServiceProtocol.self)
    }

    public override func applicationWillEnterForeground(_ application: UIApplication) {}

    public override func applicationDidEnterBackground(_ application: UIApplication) {}

    public override func applicationWillTerminate(_ application: UIApplication) {}

    private func registForbiddenEvent() {}

    private func registerRoutes() {}

    private func registerSettings() {}

    // MARK: - Injection

    private func setupPhoneNumberFetcherForFeedbackUtil() {}
}
