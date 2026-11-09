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
import TangemUI

final class CollectiblesWelcomeViewModel: ObservableObject, Identifiable {
    // MARK: - Properties

    let signingActionButtonType: SigningActionButtonViewType

    private weak var routable: (any CollectiblesWelcomeRoutable)?
    private let onboarder: (any CollectiblesOnboarder)?
    private let purpose: Purpose

    // [REDACTED_TODO_COMMENT]
    var title: String {
        switch purpose {
        case .accountCreation: Localization.collectiblesWelcomeTitle
        case .reconnection: "Reconnect Tangem Packs account"
        }
    }

    // [REDACTED_TODO_COMMENT]
    var actionTitle: String {
        switch purpose {
        case .accountCreation: Localization.collectiblesWelcomeCreateAccountButton
        case .reconnection: "Reconnect"
        }
    }

    // MARK: - Publishers

    @Published private(set) var isOnboarding = false
    @Published var alert: AlertBinder?

    // MARK: - Init

    init(
        routable: (any CollectiblesWelcomeRoutable)?,
        onboarder: (any CollectiblesOnboarder)? = nil,
        signingActionButtonType: SigningActionButtonViewType,
        purpose: Purpose = .accountCreation
    ) {
        self.routable = routable
        self.onboarder = onboarder
        self.signingActionButtonType = signingActionButtonType
        self.purpose = purpose
    }

    // MARK: - Methods

    func onActionTap() {
        CollectiblesLogger.debug("onboarding: Create Packs account button tapped")

        guard !isOnboarding else {
            CollectiblesLogger.debug("onboarding: creation is already in progress, the repeated tap is ignored")
            return
        }

        guard let onboarder else {
            CollectiblesLogger.debug("onboarding: the wallet cannot create the account -> Unsupported")
            alert = failureAlert
            return
        }

        isOnboarding = true

        Task { @MainActor [weak self] in
            do {
                try await onboarder.onboard()
                self?.isOnboarding = false
                self?.finishOnboarding()
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
                self?.alert = self?.failureAlert
            }
        }
    }

    func onLegalTermsTap(url: URL) {
        Task { @MainActor [weak self] in
            self?.routable?.openLegalTerms(url: url)
        }
    }
}

// MARK: - Private logic

private extension CollectiblesWelcomeViewModel {
    var failureAlert: AlertBinder {
        switch purpose {
        case .accountCreation: Self.creationFailureAlert
        case .reconnection: Self.reconnectionFailureAlert
        }
    }

    @MainActor
    func finishOnboarding() {
        switch purpose {
        case .accountCreation:
            CollectiblesLogger.debug("onboarding: the gacha account is ready to use, opening the stories")
            routable?.openStories()
        case .reconnection:
            CollectiblesLogger.debug("onboarding: the gacha account is reconnected, closing the screen")
            routable?.closeReconnection()
        }
    }
}

// MARK: - Alerts

private extension CollectiblesWelcomeViewModel {
    static let creationFailureAlert = AlertBinder(
        title: Localization.commonSomethingWentWrong,
        message: Localization.collectiblesWelcomeCreationFailedMessage
    )

    static let reconnectionFailureAlert = AlertBinder(
        title: Localization.commonSomethingWentWrong,
        message: Localization.accountGenericErrorDialogMessage
    )
}

// MARK: - Auxiliary types

extension CollectiblesWelcomeViewModel {
    enum Purpose {
        case accountCreation
        case reconnection
    }
}
