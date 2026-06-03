//
//  AddFundsBannerVisibilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

protocol AddFundsBannerVisibilityProvider: AnyObject {
    var shouldShow: Bool { get }
    var shouldShowPublisher: AnyPublisher<Bool, Never> { get }
}

final class CommonAddFundsBannerVisibilityProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let shouldShowSubject: CurrentValueSubject<Bool, Never>
    private var bag = Set<AnyCancellable>()

    fileprivate init() {
        // Stay hidden until balances of all wallets are actually loaded.
        shouldShowSubject = CurrentValueSubject(false)

        guard FeatureProvider.isAvailable(.addFundsStage1) else {
            return
        }

        bind()
    }
}

// MARK: - Private methods

private extension CommonAddFundsBannerVisibilityProvider {
    func bind() {
        userWalletRepository.eventProvider
            .filter { Self.isBalanceAffectingEvent($0) }
            .mapToVoid()
            .prepend(())
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, _ in
                provider.makeShouldShowPublisher()
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { provider, shouldShow in
                provider.shouldShowSubject.send(shouldShow)
            }
            .store(in: &bag)
    }

    func makeShouldShowPublisher() -> AnyPublisher<Bool, Never> {
        let balancePublishers = userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map(\.totalBalancePublisher)

        guard balancePublishers.isNotEmpty else {
            return Just(false).eraseToAnyPublisher()
        }

        return balancePublishers
            .combineLatest()
            .map { states in
                let allLoaded = states.allSatisfy { state in
                    switch state {
                    case .loaded, .empty: true
                    case .loading, .failed: false
                    }
                }
                let hasPositiveBalance = states.contains { $0.hasAnyPositiveBalance }
                return allLoaded && !hasPositiveBalance
            }
            .eraseToAnyPublisher()
    }

    static func isBalanceAffectingEvent(_ event: UserWalletRepositoryEvent) -> Bool {
        switch event {
        case .unlocked, .locked, .inserted, .unlockedWallet, .deleted:
            return true
        case .selected, .reordered:
            return false
        }
    }
}

// MARK: - AddFundsBannerVisibilityProvider

extension CommonAddFundsBannerVisibilityProvider: AddFundsBannerVisibilityProvider {
    var shouldShow: Bool {
        shouldShowSubject.value
    }

    var shouldShowPublisher: AnyPublisher<Bool, Never> {
        shouldShowSubject.removeDuplicates().eraseToAnyPublisher()
    }
}

// MARK: - Injection

private struct AddFundsBannerVisibilityProviderKey: InjectionKey {
    static var currentValue: AddFundsBannerVisibilityProvider = CommonAddFundsBannerVisibilityProvider()
}

extension InjectedValues {
    var addFundsBannerVisibilityProvider: AddFundsBannerVisibilityProvider {
        get { Self[AddFundsBannerVisibilityProviderKey.self] }
        set { Self[AddFundsBannerVisibilityProviderKey.self] = newValue }
    }
}
