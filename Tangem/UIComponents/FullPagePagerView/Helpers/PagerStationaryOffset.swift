//
//  PagerStationaryOffset.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Environment Keys

struct PagerStationaryOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

struct PagerStationaryOpacityKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var pagerStationaryOffset: CGFloat {
        get { self[PagerStationaryOffsetKey.self] }
        set { self[PagerStationaryOffsetKey.self] = newValue }
    }

    var pagerStationaryOpacity: CGFloat {
        get { self[PagerStationaryOpacityKey.self] }
        set { self[PagerStationaryOpacityKey.self] = newValue }
    }
}

// MARK: - View Modifier

/// Applies a counter-scroll offset that cancels horizontal pager movement,
/// making the view appear stationary while remaining inside the ScrollView
/// (so swipe gestures pass through naturally).
///
/// Uses distance-based opacity so only the nearest page's stationary elements
/// are fully visible, preventing overlap from adjacent pages.
struct PagerStationaryModifier: ViewModifier {
    @Environment(\.pagerStationaryOffset) private var stationaryOffset
    @Environment(\.pagerStationaryOpacity) private var stationaryOpacity

    func body(content: Content) -> some View {
        content
            .offset(x: stationaryOffset)
            .opacity(stationaryOpacity)
            .allowsHitTesting(stationaryOpacity > 0)
    }
}

extension View {
    func pagerStationary() -> some View {
        modifier(PagerStationaryModifier())
    }
}
