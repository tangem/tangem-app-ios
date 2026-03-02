//
//  PagerStationaryOffset.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Environment Key

struct PagerStationaryOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var pagerStationaryOffset: CGFloat {
        get { self[PagerStationaryOffsetKey.self] }
        set { self[PagerStationaryOffsetKey.self] = newValue }
    }
}

// MARK: - View Modifier

/// Applies a counter-scroll offset that cancels horizontal pager movement,
/// making the view appear stationary while remaining inside the ScrollView
/// (so swipe gestures pass through naturally).
struct PagerStationaryModifier: ViewModifier {
    @Environment(\.pagerStationaryOffset) private var stationaryOffset

    func body(content: Content) -> some View {
        content
            .offset(x: stationaryOffset)
    }
}

extension View {
    func pagerStationary() -> some View {
        modifier(PagerStationaryModifier())
    }
}
