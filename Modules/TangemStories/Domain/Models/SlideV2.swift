//
//  SlideV2.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct SlideV2: Identifiable, Equatable {
    public let id: String
    public let order: Int
    public let title: String
    public let subtitle: String
    public let asset: AssetV2
    public let hapticAtMs: [Int]
    /// Absent (`nil`): inherit story actions. `[]`: hide actions on this slide. Non-empty: replace.
    public let actions: [StoryActionV2]?

    public init(
        id: String,
        order: Int,
        title: String,
        subtitle: String,
        asset: AssetV2,
        hapticAtMs: [Int] = [],
        actions: [StoryActionV2]? = nil
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.subtitle = subtitle
        self.asset = asset
        self.hapticAtMs = hapticAtMs
        self.actions = actions
    }
}
