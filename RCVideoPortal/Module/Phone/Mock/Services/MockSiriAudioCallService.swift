//
//  MockSiriAudioCallService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import Intents
import PhoneInterface

class MockSiriAudioCallService: SiriAudioCallServiceProtocol {
    required init() {}

    func syncSenstiveLogFlag() {}

    func moveSiriLogToLogFile() {}

    func requestSiriPermission(_ handler: ((INSiriAuthorizationStatus) -> Swift.Void)?) {}

    func removeUserInfoFromAppGroup() {}

    func clearSiriToken() {}

    func syncLoginStatusToAppGroup() {}

    func syncCurrentUserInfoToAppGroup() {}

    func syncSiriTokenToAppGroup() {}
}
