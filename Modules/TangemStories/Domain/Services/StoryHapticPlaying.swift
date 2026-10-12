//
//  StoryHapticPlaying.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
public protocol StoryHapticPlaying {
    func prepare()
    func play(_ cluster: HapticCluster)
    func stopPlayback()
    /// Releases the engine until the next `prepare()`.
    func shutdown()
}
