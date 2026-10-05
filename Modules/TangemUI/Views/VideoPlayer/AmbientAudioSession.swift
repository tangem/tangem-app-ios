//
//  AmbientAudioSession.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation

public enum AmbientAudioSession {
    /// `.ambient` mixes with other audio so the user's music is never interrupted.
    public static func configure() {
        let session = AVAudioSession.sharedInstance()

        guard session.category != .ambient || session.categoryOptions != .mixWithOthers else { return }

        try? session.setCategory(.ambient, options: [.mixWithOthers])
    }
}
