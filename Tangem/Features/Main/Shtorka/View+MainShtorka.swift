//
//  View+MainShtorka.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

extension View {
    @ViewBuilder
    func mainShtorka() -> some View {
        if FeatureProvider.isAvailable(.nativeMarketsShtorka) {
            modifier(MainShtorkaViewModifier())
        } else {
            self
        }
    }
}

private struct MainShtorkaViewModifier: ViewModifier {
    @StateObject private var stateObject = MainShtorkaStateObject()

    func body(content: Content) -> some View {
        content
            // Read here rather than inside the sheet: the sheet's content ignores the bottom inset, so it would
            // report zero. On the main screen the value is the window's, which is what the sheet gets.
            .readGeometry(\.safeAreaInsets) { stateObject.report(safeArea: $0) }
            .shtorka(
                isPresented: $stateObject.isPresented,
                size: $stateObject.size,
                detents: stateObject.detents
            ) {
                // Placeholder until the feed moves in.
                Color.red.opacity(0.3)
                    .readGeometry(\.size.height) { stateObject.report(sheetHeight: $0) }
            }
    }
}
