//
//  CollectiblesStoriesOverlayView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct CollectiblesStoriesOverlayView: View {
    @ObservedObject var viewModel: CollectiblesStoriesViewModel

    let onShown: () -> Void
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        CollectiblesStoriesView(viewModel: viewModel)
            .opacity(isVisible ? 1 : 0)
            .task(show)
            .task(id: viewModel.isFinished, dismiss)
    }
}

private extension CollectiblesStoriesOverlayView {
    func show() async {
        withAnimation(Constants.animation) { isVisible = true }

        do {
            try await Task.sleep(for: .seconds(Constants.fadeDuration))
        } catch {
            return
        }

        onShown()
    }

    func dismiss() async {
        guard viewModel.isFinished else { return }

        withAnimation(Constants.animation) { isVisible = false }

        do {
            try await Task.sleep(for: .seconds(Constants.fadeDuration))
        } catch {
            return
        }

        onDismiss()
    }
}

// MARK: - Constants

private extension CollectiblesStoriesOverlayView {
    enum Constants {
        static let fadeDuration: TimeInterval = 0.35
        static let animation: Animation = .easeInOut(duration: fadeDuration)
    }
}
