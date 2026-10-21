//
//  PolymarketWelcomePreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarket
import TangemUI

private final class PolymarketOnboardingInteractorPreviewStub: PolymarketOnboardingInteractor {
    private let progress: [PolymarketOnboardingProgress]

    init(progress: [PolymarketOnboardingProgress]) {
        self.progress = progress
    }

    func onboard() -> AsyncStream<PolymarketOnboardingProgress> {
        AsyncStream { continuation in
            progress.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }
}

private final class PolymarketWelcomeRoutablePreviewStub: PolymarketWelcomeRoutable {
    func onboardingDidFinish(isNewAccount: Bool) {}
    func openRegionWarning() {}
    func openLegalTerms(url: URL) {}
    func dismiss() {}
}

private extension PolymarketWelcomeViewModel {
    static func preview(
        hasExistingAccount: Bool,
        progress: [PolymarketOnboardingProgress] = []
    ) -> PolymarketWelcomeViewModel {
        let viewModel = PolymarketWelcomeViewModel(
            interactor: PolymarketOnboardingInteractorPreviewStub(progress: progress),
            hasExistingAccount: hasExistingAccount,
            signingButtonType: .requiredNFCInteraction,
            coordinator: PolymarketWelcomeRoutablePreviewStub()
        )

        if !progress.isEmpty {
            viewModel.handleViewAction(.startOnboarding)
        }

        return viewModel
    }
}

// MARK: - Previews

#Preview("A wallet without an account") {
    PolymarketWelcomeView(viewModel: .preview(hasExistingAccount: false))
}

#Preview("A wallet that already has one") {
    PolymarketWelcomeView(viewModel: .preview(hasExistingAccount: true))
}

#Preview("The run in flight") {
    PolymarketWelcomeView(viewModel: .preview(hasExistingAccount: false, progress: [.awaitingSignature]))
}
