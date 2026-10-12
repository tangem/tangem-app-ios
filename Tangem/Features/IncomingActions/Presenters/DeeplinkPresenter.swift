//
//  DeeplinkPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

final class DeeplinkPresenter {
    // MARK: - Properties

    @Injected(\.overlayViewPresenter) private var overlayViewPresenter: OverlayViewPresenter

    private let coordinatorFactory: MainCoordinatorChildFactory

    /// The screen still loading for the last link shown. A newer link takes its place: the load is cancelled and
    /// what it brings is dropped, so the order the data arrives in can't put an older link over a newer one.
    private var loadingTask: Task<Void, Never>?

    // MARK: - Init

    init(coordinatorFactory: MainCoordinatorChildFactory) {
        self.coordinatorFactory = coordinatorFactory
    }
}

// MARK: - Presenting

@MainActor
extension DeeplinkPresenter {
    /// Shows over whatever is on screen what the link asks for. `false` — there is no screen here for it, and
    /// whoever owns that destination has to show it instead.
    func present(_ action: DeeplinkNavigationAction) -> Bool {
        guard let result = action.deeplinkOverlayProvider?.makeOverlay(in: makeContext(for: action)) else {
            return false
        }

        loadingTask?.cancel()
        loadingTask = nil

        switch result {
        case .ready(let overlay):
            overlayViewPresenter.present(overlay)

        case .loading(let load):
            loadingTask = Task { @MainActor [weak self] in
                guard let overlay = await load(), !Task.isCancelled else {
                    return
                }

                self?.overlayViewPresenter.present(overlay)
            }
        }

        return true
    }
}

@MainActor
private extension DeeplinkPresenter {
    func makeContext(for action: DeeplinkNavigationAction) -> DeeplinkOverlayContext {
        DeeplinkOverlayContext(
            id: action.id,
            coordinatorFactory: coordinatorFactory,
            // Through the presenter rather than straight to the overlay stack: the presenter dies with the
            // session it belongs to, so a flow that reports after the app has locked shows nothing over the lock.
            present: { [weak self] overlay in Task { @MainActor in self?.overlayViewPresenter.present(overlay) } },
            dismiss: { [weak self] in Task { @MainActor in self?.overlayViewPresenter.dismiss() } }
        )
    }
}
