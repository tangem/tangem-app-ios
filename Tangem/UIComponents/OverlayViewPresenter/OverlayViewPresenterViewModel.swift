//
//  OverlayViewPresenterViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

final class OverlayViewPresenterViewModel: ObservableObject {
    @Published private var presentationStack: [OverlayView] = []

    func sheet(at depth: Int) -> Binding<OverlayView?> {
        binding(at: depth, style: .sheet)
    }

    func fullScreenCover(at depth: Int) -> Binding<OverlayView?> {
        binding(at: depth, style: .fullScreenCover)
    }
}

// MARK: - OverlayViewPresenter

extension OverlayViewPresenterViewModel: OverlayViewPresenter {
    func present(_ view: OverlayView) {
        presentIfPossible(view)
    }

    func dismiss() {
        hideTopView()
    }
}

// MARK: - Private

private extension OverlayViewPresenterViewModel {
    @MainActor
    func presentIfPossible(_ view: OverlayView) {
        guard !presentationStack.contains(where: { $0.id == view.id }) else {
            AppLogger.debug("View with \(view.id) is already in the stack, not presenting again.")
            return
        }

        if view.animated {
            presentationStack.append(view)
        } else {
            withoutAnimations { presentationStack.append(view) }
        }
    }

    @MainActor
    func hideTopView() {
        guard let top = presentationStack.last else {
            AppLogger.debug("Presentation stack is empty, nothing to dismiss.")
            return
        }

        if top.animated {
            presentationStack.removeLast()
        } else {
            withoutAnimations { presentationStack.removeLast() }
        }
    }

    func binding(at depth: Int, style: OverlayView.PresentationStyle) -> Binding<OverlayView?> {
        Binding(get: { [weak self] in
            guard let item = self?.presentationStack[safe: depth] else {
                return nil
            }

            return item.style == style ? item : nil
        }, set: { [weak self] newValue in
            guard let self, newValue == nil, let item = presentationStack[safe: depth], item.style == style else {
                return
            }

            // Dropping all views above otherwise they lost parent
            if item.animated {
                presentationStack.removeSubrange(depth ..< presentationStack.count)
            } else {
                withoutAnimations {
                    self.presentationStack.removeSubrange(depth ..< self.presentationStack.count)
                }
            }
        })
    }

    func withoutAnimations(block: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, block)
    }
}
