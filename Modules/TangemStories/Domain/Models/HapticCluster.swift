//
//  HapticCluster.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct HapticCluster: Equatable {
    public let startMs: Int
    /// Seconds from `startMs`, starting at zero.
    public let offsets: [TimeInterval]

    public var isBurst: Bool { offsets.count >= Constants.burstImpulseCount }

    public init(startMs: Int, offsets: [TimeInterval]) {
        self.startMs = startMs
        self.offsets = offsets
    }
}

// MARK: - Constants

private extension HapticCluster {
    enum Constants {
        static let burstImpulseCount = 3
    }
}
