//
//  AddAccountWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

final class AddAccountWidgetProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let candidatesSubject = CurrentValueSubject<[FeedAccountCandidate], Never>([])
    private let router: any AccountsFeedRoutable
    private var bag = Set<AnyCancellable>()
    private var walletsBag = Set<AnyCancellable>()

    init(router: any AccountsFeedRoutable) {
        self.router = router
        bind()
    }
}

// MARK: - FeedWidgetProvider

extension AddAccountWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        candidatesSubject
            .map { $0.isEmpty ? nil : FeedWidget.addAccount }
            .eraseToAnyPublisher()
    }

    func select() {
        router.openAddAccount(candidates: candidatesSubject.value)
    }
}

// MARK: - Private

private extension AddAccountWidgetProvider {
    func bind() {
        userWalletRepository.eventProvider
            .filter { event in
                switch event {
                case .selected: false
                default: true
                }
            }
            .mapToVoid()
            .prepend(())
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, _ in provider.bindWallets() }
            .store(in: &bag)
    }

    func bindWallets() {
        walletsBag.removeAll()

        let unlockedWallets = userWalletRepository.models.filter { !$0.isUserWalletLocked }

        Publishers.MergeMany(unlockedWallets.map { wallet in
            wallet.updatePublisher.filter { update in
                guard case .configurationChanged = update else { return false }
                return true
            }
        })
        .mapToVoid()
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { provider, _ in provider.bindWallets() }
        .store(in: &walletsBag)

        let wallets = unlockedWallets.filter(\.accountModelsManager.canAddCryptoAccounts)
        guard !wallets.isEmpty else {
            candidatesSubject.send([])
            return
        }

        let availability = FeedAccountAvailability(crypto: true, joint: FeatureProvider.isAvailable(.jointAccounts))

        // Keep each wallet's account models current for the limit check when an account type is selected.
        wallets
            .map { wallet in
                wallet.accountModelsManager.accountModelsPublisher
                    .map { _ in FeedAccountCandidate(wallet: wallet, availability: availability) }
                    .eraseToAnyPublisher()
            }
            .combineLatest()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, candidates in provider.candidatesSubject.send(candidates) }
            .store(in: &walletsBag)
    }
}
