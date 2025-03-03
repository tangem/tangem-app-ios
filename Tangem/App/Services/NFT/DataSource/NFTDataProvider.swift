//
//  NFTDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// [REDACTED_TODO_COMMENT]
final class NFTDataProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider

    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
    }

    // MARK: - Private functions

    private func bind() {
        userWalletRepository.eventProvider
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: NFTDataProvider.handleUserWalletRepositoryEvent))
            .store(in: &bag)
    }

    private func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(let userWalletIds):
            for userWalletId in userWalletIds {
                guard let userWallet = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
                    return
                }
                nftAvailabilityProvider.setNFTEnabled(false, for: userWallet)
            }
        default:
            break
        }
    }
}
