//
//  CommonP2PDelegatorAddressProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemStaking
import BlockchainSdk

struct CommonP2PDelegatorAddressProvider: P2PDelegatorAddressProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func delegatorAddresses() -> [String] {
        Self.ethereumDelegatorAddresses(
            from: AccountWalletModelsAggregator.walletModels(from: userWalletRepository.models)
        )
    }

    var delegatorAddressesPublisher: AnyPublisher<[String], Never> {
        let repository = userWalletRepository

        return repository
            .eventProvider
            .map { _ in () }
            .prepend(())
            .map { _ in repository.models }
            .flatMapLatest { models -> AnyPublisher<[any WalletModel], Never> in
                guard !models.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return models
                    .map { AccountWalletModelsAggregator.walletModelsPublisher(from: $0.accountModelsManager) }
                    .combineLatest()
                    .map { $0.flattened() }
                    .eraseToAnyPublisher()
            }
            .map { Self.ethereumDelegatorAddresses(from: $0) }
            .eraseToAnyPublisher()
    }

    private static func ethereumDelegatorAddresses(from walletModels: [any WalletModel]) -> [String] {
        walletModels
            .filter { walletModel in
                guard walletModel.tokenItem.isBlockchain else { return false }
                if case .ethereum = walletModel.tokenItem.blockchain {
                    return true
                }
                return false
            }
            .map(\.defaultAddressString)
    }
}
