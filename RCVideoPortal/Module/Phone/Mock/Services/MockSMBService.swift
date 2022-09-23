//
//  MockSMBService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import PhoneInterface

class MockSMBService: SMBServiceProtocol {
    required init() {}

    func switchRootViewControllerToSMB(_ setupType: SMBSetupType) {}

    func makeSMBSetupVC(urlString: String?,
                        setupType: SMBSetupType,
                        onFinishSetup: (() -> Void)?,
                        onError: (() -> Void)?) -> UIViewController {
        return UIViewController()
    }

    func shouldShowBanner() -> Bool {
        return false
    }

    func getSMBSetupType() -> SMBSetupType? {
        return nil
    }

    func getSMBSetupTypeWhenLogined() -> SMBSetupType? {
        return nil
    }

    func setAllowShowSMBSetup(_ allow: Bool) {}

    func cleanSetupFlag() {}

    func displayLoadFACError(actionHandler: (() -> Void)?) {}

    func displayAccessErrorAlert(actionHandler: (() -> Void)?) {}
}
