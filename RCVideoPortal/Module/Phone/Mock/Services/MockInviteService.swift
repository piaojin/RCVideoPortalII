//
//  MockInviteService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import PhoneInterface

class MockInviteService: InviteServiceProtocol {
    required init() {}

    func invitePersonBySMS(_ person: GlipInvitePersonModel, inviteText: String) -> SMSInvitePersonResult {
        return SMSInvitePersonResult(success: true, fromNumber: "123456", toNumber: "456789")
    }
}
