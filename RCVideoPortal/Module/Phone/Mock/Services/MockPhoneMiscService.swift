//
//  MockPhoneMiscService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import PhoneInterface
import RCCommon

final class MockGroupExtensionListLoaderImp: GroupExtensionListLoader {
    func subscribe(_ on: @escaping () -> Void) {}

    func getViewModel() -> GrupExtensionListViewModel? {
        return nil
    }

    func perform() {}

    func dispose() {}
}

final class MockPhoneContactsMatcherImp: PhoneContactsMatcher {
    func setMatchedCallback(_ onMatched: @escaping (([PhoneContactMatchedModel]) -> Void)) {}

    func matchPhoneContacts(byPhoneNumbers: [String], featureType: GlipEUnifiedContactSelectorFeature) {}

    func perform() {}

    func dispose() {}
}

final class MockPhoneMiscService: PhoneMiscServiceProtocol {
    func analysisMobileOutgoingSingleCallInitiated(source: String) {}

    func phoneLog(_ tag: String, message: String, logType: GlipLogLevel, uuid: String?) {}

    func getLocalCanonical(_ phoneNumber: String) -> String {
        return ""
    }

    func isRcExtensionNumber(_ phoneNumber: String) -> Bool {
        return false
    }

    func createGroupExtensionListLoader() -> GroupExtensionListLoader {
        return MockGroupExtensionListLoaderImp()
    }

    func handleRemoteNotification(application: UIApplication, userInfo: [AnyHashable: Any], completionHandler: (UIBackgroundFetchResult) -> Void) -> Bool {
        return false
    }

    func handleTelephonySessionsEvent(application: UIApplication, userInfo: [AnyHashable: Any], completionHandler: (UIBackgroundFetchResult) -> Void) {}

    func canSendFaxNumber(_ faxNumber: String) -> Int32 {
        return 0
    }

    func observeParkLocation() {}

    func updatePhoneTabContainerTabBarItemCount(badge: TabBadge, tabBarItemType: ShowingCallLogType) {}

    func setCarrierNumber(_ number: String) {}

    func loadCallerIdsSync() -> [String]? {
        return nil
    }

    func displayE911Alert() {}

    func displayE911Alert(complete: (() -> Void)?) {}

    func setCallierIdItem(phoneNumber: String, displayName: String) {}

    func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        return false
    }

    func createPhoneContactsMatcher() -> PhoneContactsMatcher {
        return MockPhoneContactsMatcherImp()
    }

    func exportPhoneContact(dbPath: String, dbConfigPath: String, md5Key: String, needParsePhoneNumber: Bool) {}

    func setRegion(isoCode: String, areaCode: String) {}

    func formatNumber(_ number: String) -> String? {
        return nil
    }

    func getFullNumberString() -> String {
        return ""
    }
}
