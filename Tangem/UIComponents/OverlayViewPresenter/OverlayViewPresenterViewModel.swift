//
//  OverlayViewPresenterViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class OverlayViewPresenterViewModel: ObservableObject {
    /// The one screen shown over the app at a time. A newer one takes its place rather than piling on top: what
    /// the presenter shows is the answer to the last thing asked of it, and the older screen has been answered.
    @Published private(set) var presentedOverlay: OverlayView?
}

// MARK: - OverlayViewPresenter

extension OverlayViewPresenterViewModel: OverlayViewPresenter {
    func present(_ view: OverlayView) {
        guard presentedOverlay?.id != view.id else {
            AppLogger.debug("View with \(view.id) is already presented, not presenting again.")
            return
        }

        presentedOverlay = view
    }

    func dismiss() {
        presentedOverlay = nil
    }

    func dismissAll() {
        presentedOverlay = nil
    }
}

// MARK: - OverlayViewPresentingStateProvider

extension OverlayViewPresenterViewModel: OverlayViewPresentingStateProvider {
    var isPresenting: Bool {
        presentedOverlay != nil
    }

    var isPresentingPublisher: AnyPublisher<Bool, Never> {
        $presentedOverlay
            .map { $0 != nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var presentedOverlayIdPublisher: AnyPublisher<String?, Never> {
        $presentedOverlay
            .map { $0?.id }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
