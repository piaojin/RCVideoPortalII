//
//  SampleHandler.swift
//  GlipBroadcastExtension
//
//  Created by Jesse Xie on 9/20/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

import AppExtensionsBase
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    private var appGroupName: String {
        return AppGroup.commonAppGroupName
    }

    lazy var service: MobileRTCScreenShareService? = {
        let service = MobileRTCScreenShareService()
        service.appGroup = appGroupName
        service.delegate = self
        return service
    }()

    func createRcvService() -> RcvScreenShareService {
        let result = RcvScreenShareService()
        result.appGroup = appGroupName
        result.delegate = self
        return result
    }

    var rcvService: RcvScreenShareService?

    override init() {
        super.init()
    }

    deinit {
        service?.delegate = nil
        service = nil
        rcvService?.delegate = nil
        rcvService = nil
    }

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        let rcvSvc = createRcvService()
        if rcvSvc.broadcastStarted(withSetupInfo: setupInfo) {
            rcvService = rcvSvc
        } else {
            service?.broadcastStarted(withSetupInfo: setupInfo)
        }
        LogWriter.shared.log("broadcastStarted:\(setupInfo ?? [:])")
    }

    override func broadcastPaused() {
        if let rcvService = rcvService {
            rcvService.broadcastPaused()
        } else {
            service?.broadcastPaused()
        }
        LogWriter.shared.log("broadcastPaused")
    }

    override func broadcastResumed() {
        if let rcvService = rcvService {
            rcvService.broadcastResumed()
        } else {
            service?.broadcastResumed()
        }
        LogWriter.shared.log("broadcastResumed")
    }

    override func broadcastFinished() {
        if let rcvService = rcvService {
            rcvService.broadcastFinished()
        } else {
            service?.broadcastFinished()
        }
        LogWriter.shared.log("broadcastFinished")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        if let rcvService = rcvService {
            rcvService.processSampleBuffer(sampleBuffer, with: sampleBufferType)
        } else {
            service?.processSampleBuffer(sampleBuffer, with: sampleBufferType)
        }
    }
}

extension SampleHandler: MobileRTCScreenShareServiceDelegate {
    func mobileRTCScreenShareServiceFinishBroadcastWithError(_ error: Error!) {
        LogWriter.shared.log("finishBroadcastWithError:\(error.localizedDescription)")
        let nsError = error as NSError
        if nsError.code == 0 {
            var userInfo = nsError.userInfo
            userInfo[NSLocalizedDescriptionKey] = "The screen sharing or the meeting has been ended.".localized()
            userInfo[NSLocalizedFailureReasonErrorKey] = "The screen sharing or the meeting has been ended.".localized()
            let overrideDescError: NSError = NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo)
            finishBroadcastWithError(overrideDescError)
        } else {
            finishBroadcastWithError(error)
        }
    }
}

extension SampleHandler: RcvScreenShareServiceDelegate {
    private func rcvScreenShareServiceErrorToString(errorCode: Int) -> String {
        switch errorCode {
        case RCVRPRecordingErrorCommunication, RCVRPRecordingErrorSharingHasBeenFailed:
            return "The screen sharing has been stopped due to internal error.".localized()
        case RCVRPRecordingErrorMeetingOrSharingEnded:
            return "The screen sharing or the meeting has been ended.".localized()
        case RCVRPRecordingErrorSharingHasBeenCancelled, RCVRPRecordingErrorLostConnectionToHostApp:
            return "Screen sharing has ended.".localized()
        case RCVRPRecordingErrorSharingHasBeenInterrupted:
            return "Another participant has started screen sharing.".localized()
        case RCVRPRecordingErrorMeetingHasBeenEnded:
            return "This meeting has ended.".localized()
        default:
            return ""
        }
    }

    func rcvScreenShareServiceFinishBroadcastWithError(_ error: Error) {
        let nsError = error as NSError
        let errorString = rcvScreenShareServiceErrorToString(errorCode: nsError.code)
        var userInfo = nsError.userInfo
        LogWriter.shared.log("finishRCVBroadcastWithError:\(nsError.code)")
        userInfo[NSLocalizedDescriptionKey] = errorString
        userInfo[NSLocalizedFailureReasonErrorKey] = errorString
        finishBroadcastWithError(NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo))
    }
}
