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
    private var isPresenting = false

    nonisolated init() {}

    func presentIfNeeded() {
        guard !isPresenting else { return }
        isPresenting = true

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
        guard isPresenting else { return }
        overlayViewPresenter.dismiss()
        isPresenting = false
    }
}
