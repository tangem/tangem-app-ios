//
//  WelcomeV2Scene.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum WelcomeV2Scene: CaseIterable, Identifiable {
    case store
    case grow
    case pay

    var id: Self { self }

    var title: String {
        switch self {
        case .store: Localization.introductionTitle
        case .grow: Localization.introductionSceneTwoTitle
        case .pay: Localization.introductionSceneThreeTitle
        }
    }

    var subtitle: String {
        switch self {
        case .store: Localization.introductionSubtitle
        case .grow: Localization.introductionSceneTwoSubtitle
        case .pay: Localization.introductionSceneThreeSubtitle
        }
    }

    /// Bounds of the episode inside the background clip this scene belongs to, shared with Android.
    /// The pauses between them are intentional: no text is shown while one episode gives way to the next.
    private var timeline: Range<TimeInterval> {
        switch self {
        case .store: 0 ..< 3.1
        case .grow: 3.4 ..< 6.8
        case .pay: 7.1 ..< 12.4
        }
    }

    static func scene(at time: TimeInterval) -> WelcomeV2Scene? {
        allCases.first { $0.timeline.contains(time) }
    }
}
