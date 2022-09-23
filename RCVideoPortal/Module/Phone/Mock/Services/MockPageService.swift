//
//  MockPageService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import PhoneInterface

class MockPageService: PageServiceProtocol {
    required init() {}

    func switchToFaxTab(completion: (() -> Void)?) {}

    func switchToTextTab(completion: (() -> Void)?) {}

    func pushToCreateFaxViewController(with dataTrackingSource: String?, attachmentUrls: [URL]?, attachmentFiles: [GlipUploadFileModel]?) {}

    func presentToAddNewTextMessage(with prefilledText: String?, prefilledAttachments: [GlipUploadFileModel]?) {}

    func jumpToCallLogFromScheme() {}

    func createPage(_ type: PhonePageType) -> UIViewController {
        return UIViewController()
    }
}
