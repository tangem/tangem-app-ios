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
    func mainShtorka(coordinator: FeedCoordinator?, presentsAppOverlays: Bool) -> some View {
        if FeatureProvider.isAvailable(.nativeMarketsShtorka), let coordinator {
            modifier(MainShtorkaViewModifier(coordinator: coordinator, presentsAppOverlays: presentsAppOverlays))
        } else {
            self
        }
    }
}

private struct MainShtorkaViewModifier: ViewModifier {
    @Injected(\.appOverlaysDependencies.overlayViewPresenterViewModel) private var overlayViewPresenterViewModel: OverlayViewPresenterViewModel

    let coordinator: FeedCoordinator
    let presentsAppOverlays: Bool

    @ObservedObject private var stateObject: MainShtorkaStateObject

    init(coordinator: FeedCoordinator, presentsAppOverlays: Bool) {
        self.coordinator = coordinator
        self.presentsAppOverlays = presentsAppOverlays
        stateObject = coordinator.shtorkaStateObject
    }

    func body(content: Content) -> some View {
        content
            .background {
                MainShtorkaOverlayPresenter(viewModel: overlayViewPresenterViewModel, isEnabled: presentsAppOverlays)
            }
            // Read here rather than inside the sheet: the sheet's content ignores the bottom inset and a floating
            // sheet moves its own insets during transitions. On the main screen the values are the window's.
            .background {
                Color.clear
                    .onGeometryChange(for: EdgeInsets.self, of: { $0.safeAreaInsets }) { insets in
                        stateObject.report(safeArea: insets)
                    }
                    .onGeometryChange(for: CGFloat.self, of: {
                        $0.size.height + $0.safeAreaInsets.top + $0.safeAreaInsets.bottom
                    }) { height in
                        stateObject.report(window: height)
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
                    // The system glass background stretches during a drag and jumps back when it ends on iOS 26.
                    // A custom material keeps the native detent transition continuous.
                    .presentationBackground(.ultraThinMaterial)
                    .background {
                        Color.clear
                            .readGeometry { geometry in
                                stateObject.report(sheetHeight: geometry.size.height + geometry.safeAreaInsets.bottom)
                            }
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                    }
                    // The one place the sheet's state crosses into the screens it pushes: the state object stays
                    // in the feed, and a screen opened outside the sheet keeps the defaults.
                    .environment(\.mainShtorkaSize, stateObject.size)
                    .environment(\.mainShtorkaContentIsCollapsed, stateObject.isContentCollapsed)
            }
    }
}

// MARK: - App overlays

private struct MainShtorkaOverlayPresenter: View {
    @ObservedObject var viewModel: OverlayViewPresenterViewModel
    let isEnabled: Bool

    var body: some View {
        NavHolder()
            .shtorkaCompatibleSheet(item: enabledBinding(viewModel.sheet(at: 0))) { item in
                item.view
                    .modifier(OverlayViewPresenterModifier(viewModel: viewModel, depth: 1))
            }
            .shtorkaCompatibleFullScreenCover(item: enabledBinding(viewModel.fullScreenCover(at: 0))) { item in
                item.view
                    .modifier(OverlayViewPresenterModifier(viewModel: viewModel, depth: 1))
            }
    }

    private func enabledBinding(_ binding: Binding<OverlayView?>) -> Binding<OverlayView?> {
        Binding(
            get: { isEnabled ? binding.wrappedValue : nil },
            set: { value in
                if isEnabled {
                    binding.wrappedValue = value
                }
            }
        )
    }
}
