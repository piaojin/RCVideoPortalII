//
//  MockPhoneSettingService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import PhoneInterface
import RingCentralPhone

class MockPhoneSettingService: SettingServiceProtocol {
    required init() {}

    func getPrimaryPhoneNumberLoader(with onUpdateHandler: (() -> Void)?) -> PrimaryPhoneNumberLoaderProtocol {
        return MockPrimaryPhoneNumberLoader()
    }

    func getCallQueueConfigurator(with onUpdateHandler: (() -> Void)?,
                                  onAcceptQueueCallSettingUpdate: ((Bool) -> Void)?) -> CallQueueConfiguratorProtocol {
        return MockCallQueueConfigurator()
    }

    func isAnswerIncomingCallsInGlip() -> Bool {
        return false
    }

    func isLoginRCWithSameAccount() -> Bool {
        return false
    }

    func canOpenBackgroundNoiseReduction() -> Bool {
        return false
    }

    func phoneNoiseReduceItemKey() -> String {
        return ""
    }
}

// MARK: - PrimaryPhoneNumberLoader

final class MockPrimaryPhoneNumberLoader: PrimaryPhoneNumberLoaderProtocol {
    init() {}

    func getPrimaryPhoneNumber() -> String? {
        return ""
    }

    func perform() {}

    func dispose() {}
}

// MARK: - CallQueueConfigurator

final class MockCallQueueConfigurator: CallQueueConfiguratorProtocol {
    func perform() {}

    func dispose() {}

    // MARK: - CallQueueConfiguratorProtocol

    func setAcceptQueueCallToggleStatus(toggleState: GlipEToggleState) {}

    func isCallQueueListShouldShow() -> Bool {
        return false
    }

    func acceptQueueCallStatus() -> GlipEToggleState {
        return .off
    }
}
