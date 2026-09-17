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
        guard !isOnboarding else { return }

        guard let onboarder else {
            alert = Self.creationFailureAlert
            return
        }

        isOnboarding = true

        Task { @MainActor [weak self] in
            do {
                try await onboarder.onboard()
                self?.isOnboarding = false
                self?.routable?.openStories()
            } catch {
                // [REDACTED_TODO_COMMENT]
                // reaches the production log without the base58 account keys its `logs` payload
                // carries alongside it
                CollectiblesLogger.debug("Onboarding failed: \(error)")
                self?.isOnboarding = false
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
