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
    func mainShtorka(coordinator: FeedCoordinator?) -> some View {
        if FeatureProvider.isAvailable(.nativeMarketsShtorka), let coordinator {
            modifier(MainShtorkaViewModifier(coordinator: coordinator))
        } else {
            self
        }
    }
}

private struct MainShtorkaViewModifier: ViewModifier {
    let coordinator: FeedCoordinator

    @ObservedObject private var stateObject: MainShtorkaStateObject

    init(coordinator: FeedCoordinator) {
        self.coordinator = coordinator
        stateObject = coordinator.shtorkaStateObject
    }

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
                FeedCoordinatorView(coordinator: coordinator)
                    .readGeometry(\.size.height) { stateObject.report(sheetHeight: $0) }
            }
    }
}
