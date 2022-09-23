//
//  MockVoiceMailService.swift
//  RCVideoPortal
//
//  Created by Zoey Weng on 2022/8/13.
//  Copyright © 2022 RingCentral. All rights reserved.
//

import Foundation
import PhoneInterface

class MockVoiceMailService: VoiceMailServiceProtocol {
    required init() {}

    var isVoicePlayInSpeaker: Bool {
        return true
    }

    var playingItemId: Int64 {
        return 0
    }

    var playerTimeInterval: TimeInterval {
        return 0
    }

    var isPlaying: Bool {
        return false
    }

    var isDownloadFinishPlaying: Bool {
        return false
    }

    func play(item: VoiceMailItemProtocol, startInterval: TimeInterval) {}

    func stop() {}

    func updateVoiceMail(_ voiceMail: VoiceMailItemProtocol) {}

    func changeAudioRoute() {}

    func clearPlayerManagerStatusWhenExited() {}

    func clearDownloadManagerStatusWhenExited() {}

    func downloadVoiceMail(_ voiceMail: VoiceMailItemProtocol) {}
}
