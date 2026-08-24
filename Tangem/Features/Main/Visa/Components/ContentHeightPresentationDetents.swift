//
//  ContentHeightPresentationDetents.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

private struct ContentHeightPresentationDetents: ViewModifier {
    @State private var contentHeight: CGFloat

    init(idealHeight: CGFloat) {
        contentHeight = idealHeight
    }

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .presentationDetents([.height(contentHeight)])
            .readGeometry { contentHeight = $0.size.height }
    }
}

extension View {
    func presentationDetents(idealHeight: CGFloat) -> some View {
        modifier(ContentHeightPresentationDetents(idealHeight: idealHeight))
    }
}
