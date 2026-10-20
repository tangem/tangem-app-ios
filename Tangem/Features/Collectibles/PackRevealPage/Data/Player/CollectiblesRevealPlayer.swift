//
//  CollectiblesRevealPlayer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine

@MainActor
protocol CollectiblesRevealPlayer: AnyObject {
    var videoPlayerPublisher: AnyPublisher<AVPlayer?, Never> { get }

    func play(videoURL: URL?) async throws -> CollectiblesRevealPlayerResult
    func skip()
}
