//
//  LogWriter.swift
//  Glip
//
//  Created by Nelson Wu on 7/30/20.
//  Copyright © 2020 RingCentral. All rights reserved.
//

import AppExtensionsBase
import Foundation

class LogWriter {
    static let shared: LogWriter = LogWriter()
    private let logger: AppGroupLogger = {
        return AppGroupLogger(fileName: "Broadcast", appGroupIdentifier: AppGroup.commonAppGroupName)
    }()

    func log(_ message: String, isSensitive: Bool = false) {
        logger.logs("\(message)", isSensitive: isSensitive)
    }
}
