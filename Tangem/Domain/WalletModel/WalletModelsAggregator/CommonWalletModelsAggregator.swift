//
//  CommonWalletModelsAggregator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

final class CommonWalletModelsAggregator: WalletModelsAggregator {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let walletModelsPublisher: AnyPublisher<[any WalletModel], Never>

    private let walletModelsSubject = CurrentValueSubject<[any WalletModel], Never>([])

    private var bag: Set<AnyCancellable> = []

    init() {
        walletModelsPublisher = walletModelsSubject.eraseToAnyPublisher()
        bind()
    }
}

// MARK: - Private methods

private extension CommonWalletModelsAggregator {
    func bind() {
        makeUnlockedUserWalletsPublisher()
            .flatMapLatest { unlockedUserWallets -> AnyPublisher<[any WalletModel], Never> in
                let publishers = unlockedUserWallets.map {
                    AccountWalletModelsAggregator.walletModelsPublisher(from: $0.accountModelsManager)
                }

                guard publishers.isNotEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return publishers
                    .combineLatest()
                    .map { $0.flattened() }
                    .eraseToAnyPublisher()
            }
            .subscribe(walletModelsSubject)
            .store(in: &bag)
    }

    func makeUnlockedUserWalletsPublisher() -> AnyPublisher<[any UserWalletModel], Never> {
        let updatePublisher = userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .filter { aggregator, event in
                aggregator.isTarget(repositoryEvent: event)
            }
            .withWeakCaptureOf(self)
            .map { aggregator, _ in
                aggregator.unlockedUserWallets()
            }

        return Just(unlockedUserWallets())
            .merge(with: updatePublisher)
            .eraseToAnyPublisher()
    }

    func unlockedUserWallets() -> [any UserWalletModel] {
        userWalletRepository.models.filter { !$0.isUserWalletLocked }
    }

    func isTarget(repositoryEvent: UserWalletRepositoryEvent) -> Bool {
        switch repositoryEvent {
        case .locked, .unlocked, .inserted, .unlockedWallet, .deleted: true
        case .selected, .reordered: false
        }
    }
}
