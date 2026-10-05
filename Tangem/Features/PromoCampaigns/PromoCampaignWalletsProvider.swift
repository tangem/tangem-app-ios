//
//  PromoCampaignWalletsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

protocol PromoCampaignWalletsProviding {
    var wallets: [PromoCampaignWallet] { get }
    var walletsPublisher: AnyPublisher<[PromoCampaignWallet], Never> { get }
}

struct CommonPromoCampaignWalletsProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
}

// MARK: - PromoCampaignWalletsProviding

extension CommonPromoCampaignWalletsProvider: PromoCampaignWalletsProviding {
    var wallets: [PromoCampaignWallet] {
        userWalletRepository.models.compactMap { model in
            guard let identityProvider = model as? PromoCampaignIdentityProviding else {
                return nil
            }

            return PromoCampaignWallet(userWalletId: model.userWalletId, identity: identityProvider.promoCampaignIdentity)
        }
    }

    var walletsPublisher: AnyPublisher<[PromoCampaignWallet], Never> {
        userWalletRepository.eventProvider
            .map { _ in }
            .prepend(())
            .map { _ in Self.configurationChanges(of: userWalletRepository.models).prepend(()) }
            .switchToLatest()
            .map { _ in wallets }
            .removeDuplicates { Set($0) == Set($1) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonPromoCampaignWalletsProvider {
    static func configurationChanges(of models: [UserWalletModel]) -> AnyPublisher<Void, Never> {
        Publishers.MergeMany(models.map { model in
            model.updatePublisher
                .filter { result in
                    switch result {
                    case .configurationChanged:
                        true
                    case .nameDidChange:
                        false
                    }
                }
                .map { _ in }
        })
        .eraseToAnyPublisher()
    }
}
