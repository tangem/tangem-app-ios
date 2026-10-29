//
//  PolymarketAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol PolymarketAvailabilityProvider {
    func isAvailablePublisher(hasAccount: @escaping () -> Bool) -> AnyPublisher<Bool, Never>
}

/// The feature opens when the variants fetched in this session for the selected wallet enroll it;
/// variants cached by an earlier session or another wallet never open it.
/// A wallet that already has an account keeps the feature on its own, without the experiment.
struct CommonPolymarketAvailabilityProvider: PolymarketAvailabilityProvider {
    private let experimentService: ExperimentService
    private let accountPresenceChangesPublisher: AnyPublisher<Void, Never>

    init(
        experimentService: ExperimentService = InjectedValues[\.experimentService],
        accountPresenceChangesPublisher: AnyPublisher<Void, Never> = AppSettings.shared.$polymarketHasAccount.mapToVoid().eraseToAnyPublisher()
    ) {
        self.experimentService = experimentService
        self.accountPresenceChangesPublisher = accountPresenceChangesPublisher
    }

    var isAvailable: Bool {
        experimentService.hasFreshVariants && experimentService.isOn(.polymarket, variant: .on)
    }

    func isAvailable(hasAccount: () -> Bool) -> Bool {
        hasAccount() || isAvailable
    }

    func isAvailablePublisher(hasAccount: @escaping () -> Bool) -> AnyPublisher<Bool, Never> {
        experimentService
            .variantsPublisher
            .merge(with: accountPresenceChangesPublisher)
            .map { _ in isAvailable(hasAccount: hasAccount) }
            .prepend(isAvailable(hasAccount: hasAccount))
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Injection

private struct PolymarketAvailabilityProviderKey: InjectionKey {
    static var currentValue: PolymarketAvailabilityProvider = CommonPolymarketAvailabilityProvider()
}

extension InjectedValues {
    var polymarketAvailabilityProvider: PolymarketAvailabilityProvider {
        get { Self[PolymarketAvailabilityProviderKey.self] }
        set { Self[PolymarketAvailabilityProviderKey.self] = newValue }
    }
}
