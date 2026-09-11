//
//  MainScreenUIOrderedWalletModelsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class MainScreenUIOrderedWalletModelsProvider {
    private let userWalletModel: UserWalletModel
    private var adapters: [ObjectIdentifier: TokenSectionsAdapter] = [:]

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> {
        userWalletModel
            .accountModelsManager
            .cryptoAccountModelsPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, cryptoAccountModels -> AnyPublisher<[any WalletModel], Never> in
                guard !cryptoAccountModels.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }
                return cryptoAccountModels
                    .map { provider.organizedWalletModelsPublisher(for: $0) }
                    .combineLatest()
                    .map { $0.flatMap { $0 } }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func organizedWalletModelsPublisher(
        for cryptoAccount: any CryptoAccountModel
    ) -> AnyPublisher<[any WalletModel], Never> {
        let adapter = makeOrGetCachedAdapter(for: cryptoAccount)
        return adapter
            .organizedSections(from: cryptoAccount.walletModelsManager.walletModelsPublisher, on: .main)
            .map { sections in sections.flatMap(\.walletModels) }
            .eraseToAnyPublisher()
    }

    private func makeOrGetCachedAdapter(for cryptoAccount: any CryptoAccountModel) -> TokenSectionsAdapter {
        let key = ObjectIdentifier(cryptoAccount)
        if let cached = adapters[key] {
            return cached
        }
        let userTokensManager = cryptoAccount.userTokensManager
        let adapter = TokenSectionsAdapter(
            userTokensManager: userTokensManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
        adapters[key] = adapter
        return adapter
    }
}

// MARK: - Settled models

extension MainScreenUIOrderedWalletModelsProvider {
    /// Wallet models with their fiat balances settled (no longer loading) — a most-funded pick
    /// made before balances land would be arbitrary. Empty on failure.
    func settledWalletModels() async -> [any WalletModel] {
        do {
            let walletModels = try await walletModelsPublisher.async()
            guard !walletModels.isEmpty else { return [] }

            _ = try await walletModels
                .map { $0.fiatAvailableBalanceProvider.balanceTypePublisher.first(where: { !$0.isLoading }) }
                .combineLatest()
                .async()

            return walletModels
        } catch {
            return []
        }
    }
}
