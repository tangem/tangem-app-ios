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
            // Read here rather than inside the sheet: the sheet's content ignores the bottom inset and a floating
            // sheet moves its own insets during transitions. On the main screen the values are the window's.
            .background {
                Color.clear
                    .readGeometry { geometry in
                        let insets = geometry.safeAreaInsets
                        stateObject.report(safeArea: insets)
                        stateObject.report(window: geometry.size.height + insets.top + insets.bottom)
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .shtorka(
                isPresented: $stateObject.isPresented,
                size: $stateObject.size,
                detents: stateObject.detents,
                expansionProgress: stateObject.expansionProgressPublisher
            ) {
                FeedCoordinatorView(coordinator: coordinator)
                    .background {
                        Color.clear
                            .readGeometry { geometry in
                                stateObject.report(sheetHeight: geometry.size.height + geometry.safeAreaInsets.bottom)
                            }
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                    }
            }
    }
}
