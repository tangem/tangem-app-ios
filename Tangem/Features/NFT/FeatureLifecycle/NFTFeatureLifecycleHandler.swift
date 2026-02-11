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
import TangemNFT

protocol NFTFeatureLifecycleHandling {
    var walletsWithNFTEnabledPublisher: AnyPublisher<Set<UserWalletId>, Never> { get }
    func startObserving()
}

final class NFTFeatureLifecycleHandler: NFTFeatureLifecycleHandling {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider

    private var walletsWithNFTEnabled: Set<UserWalletId> {
        userWalletRepository
            .models
            .filter { nftAvailabilityProvider.isNFTEnabled(for: $0) }
            .map(\.userWalletId)
            .toSet()
    }

    private var bag: Set<AnyCancellable> = []

    func startObserving() {
        bind()
    }

    var walletsWithNFTEnabledPublisher: AnyPublisher<Set<UserWalletId>, Never> {
        nftAvailabilityProvider
            .didChangeNFTAvailabilityPublisher
            .withWeakCaptureOf(self)
            .map(\.0.walletsWithNFTEnabled)
            .eraseToAnyPublisher()
    }

    // MARK: - Private functions

    private func bind() {
        userWalletRepository
            .eventProvider
            .receiveOnMain()
            .sink(receiveValue: weakify(self, forFunction: NFTFeatureLifecycleHandler.handleUserWalletRepositoryEvent))
            .store(in: &bag)

        walletsWithNFTEnabledPublisher
            .sink(receiveValue: weakify(self, forFunction: NFTFeatureLifecycleHandler.clearNFTCacheIfNeeded))
            .store(in: &bag)
    }

    private func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(let userWalletIds, _):
            for userWalletId in userWalletIds {
                clearNFTCache(forUserWalletWithId: userWalletId)
                disableNFTAvailability(forUserWalletWithId: userWalletId)
            }
        default:
            break
        }
    }

    private func clearNFTCacheIfNeeded(walletsWithNFTEnabled: Set<UserWalletId>) {
        for userWallet in userWalletRepository.models where !walletsWithNFTEnabled.contains(userWallet.userWalletId) {
            clearNFTCache(forUserWalletWithId: userWallet.userWalletId)
        }
    }

    private func clearNFTCache(forUserWalletWithId userWalletId: UserWalletId) {
        let cache = NFTCache(userWalletId: userWalletId)
        cache.clear()
    }

    private func disableNFTAvailability(forUserWalletWithId userWalletId: UserWalletId) {
        nftAvailabilityProvider.setNFTEnabled(false, forUserWalletWithId: userWalletId)
    }
}
