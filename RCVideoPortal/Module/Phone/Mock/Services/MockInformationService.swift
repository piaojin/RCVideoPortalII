//
//  MockInformationService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import PhoneInterface

class MockInformationService: InformationServiceProtocol {
    required init() {}

    func getDigitalLineAssignmentStatus() -> Bool {
        return false
    }

    func removeDigitalLineAssignmentStatus() {}

    func isRcE911Required() -> Bool {
        return false
    }

    func isMmsBetaFlagOn() -> Bool {
        return false
    }
}
