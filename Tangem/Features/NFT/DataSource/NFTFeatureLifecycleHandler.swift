//
//  NFTDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol NFTFeatureLifecycleHandling {
    var walletsWithNFTEnabledPublisher: AnyPublisher<Set<UserWalletId>, Never> { get }
    func startObserving()
}

final class NFTFeatureLifecycleHandler: NFTFeatureLifecycleHandling {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider

    private var bag: Set<AnyCancellable> = []
    private var userWallets: [UserWalletModel] = []

    init() {
        self.userWallets = userWalletRepository.models
    }

    func startObserving() {
        bind()
    }

    var walletsWithNFTEnabledPublisher: AnyPublisher<Set<UserWalletId>, Never> {
        nftAvailabilityProvider.didChangeNFTAvailabilityPublisher
            .map { [weak self] in
                guard let self else { return Set() }

                return userWallets
                    .filter { self.nftAvailabilityProvider.isNFTEnabled(for: $0) }
                    .map(\.userWalletId)
                    .toSet()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private functions

    private func bind() {
        userWalletRepository.eventProvider
            .receiveOnMain()
            .sink(receiveValue: weakify(self, forFunction: NFTFeatureLifecycleHandler.handleUserWalletRepositoryEvent))
            .store(in: &bag)
    }

    private func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(let userWalletIds):
            for userWalletId in userWalletIds {
                nftAvailabilityProvider.setNFTEnabled(false, forUserWalletWithId: userWalletId)
            }
        default:
            break
        }

        userWallets = userWalletRepository.models
    }
}
