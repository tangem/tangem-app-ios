//
//  ContentHeightPresentationDetents.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

private struct ContentHeightPresentationDetents: ViewModifier {
    @State private var contentHeight: CGFloat

    init(idealHeight: CGFloat) {
        assert(idealHeight > 0, "A zero detent collapses the sheet to its minimum height")
        contentHeight = idealHeight
    }

    func body(content: Content) -> some View {
        content
            // Keeps the measurement independent of the detent the measurement itself feeds
            .fixedSize(horizontal: false, vertical: true)
            .presentationDetents([.height(contentHeight)])
            .readGeometry(\.size.height) { contentHeight = $0.roundedToDeviceScale() }
    }
}

extension View {
    func presentationDetents(idealHeight: CGFloat) -> some View {
        modifier(ContentHeightPresentationDetents(idealHeight: idealHeight))
    }
}
