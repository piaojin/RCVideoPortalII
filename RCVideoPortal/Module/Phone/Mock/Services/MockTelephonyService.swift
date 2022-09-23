//
//  MockTelephonyService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import PhoneInterface
import RCCommon

final class MockTelephonyService: TelephonyServiceProtocol {
    init() {}

    var aecDumpEnabled: Bool = true

    var isCallInProgress: Bool = false

    func checkMakeVoipCall() -> Bool {
        return false
    }

    func startVoIPEngineIfNecessary() {}

    func endAllCalls(reason: String) {}

    func hasCall() -> Bool {
        return false
    }

    func getCallScreenShot() -> UIImage? {
        return nil
    }

    func showPhoneNumberInteractionSheet(_ phoneNumber: String) {}

    func fetchBusinessMobileNumber(initCallback: ((String?) -> Void)?, updateCallback: ((String?) -> Void)?) -> Disposable {
        MockFetchBusinessMobileNumberDisposable()
    }

    func updateLoggingSetting() {}

    func configAECDumpState(enabled: Bool) {}

    func clearAECDumpLogs() {}

    func tryMakeNativeCall(_ toPhoneNumber: String, accessCode: String, meetingCode: String) {}

    func tryMakeVoIPCallCombineWith(_ toPhoneNumber: String, accessCode: String) {}

    func tryMakeVoIPSingleCall(_ toPhoneNumber: String, accessCode: String) {}

    func tryMakeVoIPConferenceCall(_ toPhoneNumber: String, accessCode: String) {}

    func tryMakeVoIPConferenceRccCall(_ toPhoneNumber: String, accessCode: String) {}

    func makeSingleCall(_ toNumber: String, accessCode: String, meetingCode: String) {}

    func makeSingleCallWithShortSpecialFormatOption(_ toNumber: String, accessCode: String, meetingCode: String) {}

    func makeConferenceCall(_ toNumber: String, accessCode: String, meetingCode: String) {}

    func makeConferenceRccCall(_ toNumber: String, accessCode: String, meetingCode: String) {}

    func makeCallCombineWith(_ toPhoneNumber: String, accessCode: String) {}

    func chooseCallerIdMakeCallIfNeeded(lastUsedNumber: String, toNumber: String, source: String?) {}

    func handleBetaFlagStatusChange(_ betaType: GlipEBetaType) {}

    func requestMicrophonePermission(completion: (() -> Void)?) {}

    func updateVoipLDFlgs() {}

    func setMediaSetting(path: String) {}

    func stopVoIPEngine() {}

    func getCallsCount() -> Int {
        return 0
    }
}

class MockFetchBusinessMobileNumberDisposable: Disposable {
    func dispose() {}

    func perform() {}
}
