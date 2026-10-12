//
//  DebugMenuPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

@MainActor
final class DebugMenuPresenter {
    @Injected(\.overlayViewPresenter) private var overlayViewPresenter: any OverlayViewPresenter

    private static let overlayId = "DebugMenuPresenter.EnvironmentSetup"

    nonisolated init() {}

    /// The presenter shows one screen at a time and refuses the one it already shows, so asking twice is its
    /// business rather than a flag kept here — a flag would stay raised when a deeplink takes the menu's place.
    func presentIfNeeded() {
        let coordinator = EnvironmentSetupCoordinator(
            dismissAction: { [weak self] _ in self?.dismiss() },
            popToRootAction: { [weak self] _ in self?.dismiss() }
        )
        coordinator.start(with: .init())

        let rootView = DebugMenuRootView(coordinator: coordinator) { [weak self] in
            self?.dismiss()
        }

        overlayViewPresenter.present(
            OverlayView(
                id: Self.overlayId,
                view: rootView,
                style: .fullScreenCover
            )
        )
    }

    private func dismiss() {
        overlayViewPresenter.dismiss()
    }
}
