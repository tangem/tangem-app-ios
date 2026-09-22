//
//  StoryAudioSession.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation

@MainActor
enum StoryAudioSession {
    private static var isAmbientConfigured = false

    /// `.ambient` mixes with other audio so the user's music is never interrupted.
    static func activateAmbientOnce() {
        guard !isAmbientConfigured else { return }
        isAmbientConfigured = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }
}
