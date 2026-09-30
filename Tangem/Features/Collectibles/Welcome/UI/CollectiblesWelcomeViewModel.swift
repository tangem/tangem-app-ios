//
//  CollectiblesWelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLocalization
import TangemUIUtils
import TangemCollectibles

final class CollectiblesWelcomeViewModel: ObservableObject {
    // MARK: - Properties

    private weak var routable: (any CollectiblesWelcomeRoutable)?
    private let onboarder: (any CollectiblesOnboarder)?

    // MARK: - Publishers

    @Published private(set) var isOnboarding = false
    @Published var alert: AlertBinder?

    // MARK: - Init

    init(routable: (any CollectiblesWelcomeRoutable)?, onboarder: (any CollectiblesOnboarder)? = nil) {
        self.routable = routable
        self.onboarder = onboarder
    }

    // MARK: - Methods

    func onCreateAccountTap() {
        CollectiblesLogger.debug("onboarding: Create Packs account button tapped")

        guard !isOnboarding else {
            CollectiblesLogger.debug("onboarding: creation is already in progress, the repeated tap is ignored")
            return
        }

        guard let onboarder else {
            CollectiblesLogger.debug("onboarding: the wallet cannot create the account -> Unsupported")
            alert = Self.creationFailureAlert
            return
        }

        isOnboarding = true

        Task { @MainActor [weak self] in
            do {
                try await onboarder.onboard()
                CollectiblesLogger.debug("onboarding: the gacha account is ready to use, opening the stories")
                self?.isOnboarding = false
                self?.routable?.openStories()
            } catch {
                self?.isOnboarding = false

                guard !error.isCancellationError else {
                    CollectiblesLogger.debug("onboarding: account creation cancelled")
                    return
                }

                // [REDACTED_TODO_COMMENT]
                // reaches the production log without the base58 account keys its `logs` payload
                // carries alongside it
                CollectiblesLogger.debug("onboarding: account creation failed: \(error)")
                self?.alert = Self.creationFailureAlert
            }
        }
    }

    func onLegalTermsTap(url: URL) {
        Task { @MainActor [weak self] in
            self?.routable?.openLegalTerms(url: url)
        }
    }
}

// MARK: - Alerts

private extension CollectiblesWelcomeViewModel {
    static let creationFailureAlert = AlertBinder(
        title: Localization.commonSomethingWentWrong,
        message: Localization.collectiblesWelcomeCreationFailedMessage
    )
}
