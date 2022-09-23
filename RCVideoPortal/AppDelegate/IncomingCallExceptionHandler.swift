//
//  IncomingCallExceptionHandler.swift
//  Glip
//
//  Created by Leon Xiao on 2020/12/25.
//  Copyright © 2020 RingCentral. All rights reserved.
//

import AVFoundation
import CallKit
import os.log
import PushKit
import RCCommon
import UIKit
import VideoInterface

class IncomingCallExceptionHandler: NSObject {
    private var provider: CXProvider?
    private var pushRegistry: PKPushRegistry?
    private var timer: Timer?

    public override init() {
        super.init()
        os_log("IncomingCallExceptionHandler init provider")
        provider = CXProvider(configuration: IncomingCallExceptionHandler.configuration())
        provider?.setDelegate(self, queue: DispatchQueue.main)

        os_log("IncomingCallExceptionHandler init PKPushRegistry")
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = NSSet(object: PKPushType.voIP) as? Set<PKPushType>
        pushRegistry = voipRegistry

        os_log("IncomingCallExceptionHandler init done")
    }

    static func configuration() -> CXProviderConfiguration {
        let dispalyName: String = InfoPlist.shared.getInfoValueWith(KeyCenter.kCFBundleDisplayName)
        let configuration = CXProviderConfiguration(localizedName: dispalyName.localized())
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 3
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.phoneNumber]
        configuration.includesCallsInRecents = !GlobalUtils.isDisableCallkitFeature()
        configuration.ringtoneSound = "Default.mp3"
        if let data = UIImage(named: "CallKit_Icon")?.pngData() {
            configuration.iconTemplateImageData = data
        }
        return configuration
    }

    func addTimeoutMonitor() {
        os_log("IncomingCallExceptionHandler addTimeoutMonitor")
        if timer != nil {
            stopTimeoutMonitor()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 30,
                                     repeats: false) { [weak self] timer in
            self?.stopTimeoutMonitor()
            exit(0)
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stopTimeoutMonitor() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: Incoming Calls

    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: @escaping () -> Void) {
        os_log("IncomingCallExceptionHandler reportIncomingCall")
        let update = CXCallUpdate()
        update.hasVideo = hasVideo
        update.localizedCallerName = handle
        provider?.reportNewIncomingCall(with: uuid, update: update) { error in
            completion()
        }
    }

    func scheduleLocalNotification() {
        os_log("IncomingCallExceptionHandler scheduleLocalNotification")
        let notificationCenter = UNUserNotificationCenter.current()
        let notificationCentent = UNMutableNotificationContent()
        notificationCentent.body = "To pick up incoming calls successfully, unlock your phone after rebooting the device.".localized()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
        let request = UNNotificationRequest(identifier: "com.mobile.IncomingCallExceptionHandler", content: notificationCentent, trigger: trigger)
        notificationCenter.add(request) { _ in
            os_log("IncomingCallExceptionHandler scheduleLocalNotification error")
        }
    }

    func handleVoIPPushPayload(_ payload: [AnyHashable: Any], completion: @escaping () -> Void) {
        var handle = ""
        let hasVideo = (payload["meeting_id"] as? String != nil)
        if hasVideo {
            guard let call = getVideoCall(from: payload) else {
                os_log("IncomingCallExceptionHandler payload empty")
                return
            }
            if call.action == .stop {
                os_log("IncomingCallExceptionHandler stop action")
                exit(0)
            }
            handle = call.displayName()
            os_log("IncomingCallExceptionHandler isVideo")
        } else {
            handle = payload["fromName"] as? String ?? ""
            os_log("IncomingCallExceptionHandler isAudio")
        }
        reportIncomingCall(uuid: UUID(), handle: handle, hasVideo: hasVideo) {
            os_log("IncomingCallExceptionHandler report incoming call success")
            completion()
        }
    }

    func getVideoCall(from payload: [AnyHashable: Any]) -> VideoCall? {
        var videoCall: VideoCall?
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            videoCall = try JSONDecoder().decode(VideoCall.self, from: data)
        } catch {
            os_log("IncomingCallExceptionHandler Decoder payload failed")
        }
        return videoCall
    }
}

extension VideoCall {
    func displayName() -> String {
        if let name = self.name, !name.isEmpty {
            return name
        } else if let name = self.inviter?.name, !name.isEmpty {
            return name
        } else {
            return meetingID + " - " + "Video Meeting".localized()
        }
    }
}

extension IncomingCallExceptionHandler: CXProviderDelegate {
    // MARK: CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {}

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        os_log("IncomingCallExceptionHandler CXAnswerCallAction")
        scheduleLocalNotification()
        stopTimeoutMonitor()
        action.fulfill()
        exit(0)
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        os_log("IncomingCallExceptionHandler CXEndCallAction")
        stopTimeoutMonitor()
        action.fulfill()
        exit(0)
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {}

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {}
}

extension IncomingCallExceptionHandler: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {}

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        os_log("IncomingCallExceptionHandler didReceiveIncomingPushWith")
        addTimeoutMonitor()
        handleVoIPPushPayload(payload.dictionaryPayload, completion: completion)
    }
}
