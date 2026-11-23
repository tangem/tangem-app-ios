//
//  CommonDerivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

/// One instance per unique user wallet model.
final class CommonDerivationManager {
    private let keysRepository: KeysRepository

    private weak var keysDerivingProvider: KeysDerivingProvider?
    private var accountModelsManagerSubscription: AnyCancellable?

    private let pendingDerivationsSubject = CurrentValueSubject<[PendingDerivation], Never>([])
    private let derivationProcessor = SingleTaskProcessor<Void, any Error>()

    init(keysRepository: KeysRepository) {
        self.keysRepository = keysRepository
    }
}

// MARK: - DerivationManager protocol conformance

extension CommonDerivationManager: DerivationManager {
    func shouldDeriveKeys(networksToRemove: [BlockchainNetwork], networksToAdd: [BlockchainNetwork]) -> Bool {
        ensureConfigured()

        guard let interactor = keysDerivingProvider?.keysDerivingInteractor, interactor.requiresCard else {
            return false
        }

        let keys = keysRepository.keys
        let derivationsToAdd = networksToAdd.flatMap { PendingDerivationHelper.pendingDerivations(network: $0, keys: keys) }

        // Filter pending derivations by removing those that belong to networks scheduled for removal.
        // This ensures we only consider derivations that will still be relevant after the update.
        let filteredPendingDerivations = pendingDerivationsSubject.value.filter { !networksToRemove.contains($0.network) }

        // Derivation is needed if the user adds networks requiring a card,
        // or if unresolved derivations remain for existing networks.
        return derivationsToAdd.isNotEmpty || filteredPendingDerivations.isNotEmpty
    }

    func deriveKeys() async throws {
        ensureConfigured()

        try await derivationProcessor.execute { [weak self] in
            try await self?.startDeriveKeys()
        }

        let remainingNetworksCount = pendingDerivationsSubject.value.unique(by: \.network).count

        if remainingNetworksCount > 0 {
            PendingDerivationsLogger.warning("\(remainingNetworksCount) networks are still pending after the card session")
        }
    }
}

// MARK: - PendingDerivationStatusProvider protocol conformance

extension CommonDerivationManager: PendingDerivationStatusProvider {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        pendingDerivationsSubject
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        pendingDerivationsSubject
            .map { $0.unique(by: \.network).count }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - DerivationManagerDependenciesConfigurable protocol conformance

extension CommonDerivationManager: DerivationManagerDependenciesConfigurable {
    func configure(with derivingProvider: KeysDerivingProvider) {
        assert(keysDerivingProvider == nil, "An attempt to override already configured keysDerivingProvider instance")

        keysDerivingProvider = derivingProvider
    }

    func configure(with accountModelsManager: AccountModelsManager) {
        assert(accountModelsManagerSubscription == nil, "An attempt to override already configured accountModelsManager subscription")

        accountModelsManagerSubscription = accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, accountModels -> AnyPublisher<[PendingDerivation], Never> in
                guard accountModels.isNotEmpty else {
                    return .just(output: [])
                }

                return accountModels
                    .flatMap { manager.accounts(in: $0) }
                    .map {
                        $0.pendingDerivationProvider
                            .pendingDerivationsPublisher
                            .receive(on: DispatchQueue.main)
                    }
                    .combineLatest()
                    .map { $0.flattened() }
                    .eraseToAnyPublisher()
            }
            .subscribe(pendingDerivationsSubject)
    }
}

// MARK: - Private implementation

private extension CommonDerivationManager {
    func ensureConfigured() {
        assert(
            keysDerivingProvider != nil && accountModelsManagerSubscription != nil,
            "CommonDerivationManager is not configured with required dependencies"
        )
    }

    @MainActor
    func startDeriveKeys() async throws {
        try await Task.sleep(for: .seconds(Constants.pendingDerivationsUpdateDelay))
        let pendingDerivations = pendingDerivationsSubject.value

        guard pendingDerivations.isNotEmpty else {
            PendingDerivationsLogger.info("Nothing is pending, no card session")
            return
        }

        guard let interactor = keysDerivingProvider?.keysDerivingInteractor else {
            PendingDerivationsLogger.error(error: DerivationManagerError.keysDerivingProviderNotFound)
            throw DerivationManagerError.keysDerivingProviderNotFound
        }

        let pendingDerivationsKeyed = PendingDerivationHelper.pendingDerivationPathsKeyedByPublicKeys(pendingDerivations)
        let networksCount = pendingDerivations.unique(by: \.network).count
        let pathsCount = pendingDerivationsKeyed.values.reduce(0) { $0 + $1.count }

        PendingDerivationsLogger.info("Deriving \(pathsCount) paths for \(networksCount) networks")

        let response: DerivationResult

        do {
            response = try await interactor.deriveKeys(derivations: pendingDerivationsKeyed)
        } catch {
            PendingDerivationsLogger.error("Failed to derive \(pathsCount) paths for \(networksCount) networks", error: error)
            throw error
        }

        let derivedKeysCount = response.values.reduce(0) { $0 + $1.keys.count }
        PendingDerivationsLogger.info("Derived \(derivedKeysCount) of \(pathsCount) paths")

        keysRepository.update(derivations: response)
        try await Task.sleep(for: .seconds(Constants.deriveKeysCompletionDelay))
    }
}

// MARK: - Accounts

private extension CommonDerivationManager {
    func accounts(in accountModel: AccountModel) -> [any BaseAccountModel] {
        switch accountModel {
        case .standard(.single(let cryptoAccountModel)):
            return [cryptoAccountModel]
        case .standard(.multiple(let cryptoAccountModels)):
            return cryptoAccountModels
        case .joint(let jointAccountModels):
            return jointAccountModels
        case .tangemPay(let tangemPayAccountModel):
            return [tangemPayAccountModel]
        case .polymarket(let polymarketAccountModel):
            return [polymarketAccountModel]
        case .collectibles(let collectiblesAccountModel):
            return [collectiblesAccountModel]
        }
    }
}

// MARK: - Constants

private extension CommonDerivationManager {
    enum Constants {
        /// Delay to get more time to update UI and hide generate addresses sheet under the hood
        /// Taken as is from CommonDerivationManager, looks like a workaround for some UI issues
        static let deriveKeysCompletionDelay = 0.2

        /// Time for a token write to reach `pendingDerivationsSubject` before a card session reads it
        /// The list arrives through the repository's storage publisher and a hop to main, so a session that reads it
        /// right after the write sees the old list and derives nothing
        static let pendingDerivationsUpdateDelay = 0.3
    }
}
