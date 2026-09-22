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
    private weak var router: FeedWidgetsRoutable?
    private var bag = Set<AnyCancellable>()
    private var walletsBag = Set<AnyCancellable>()

    init(router: FeedWidgetsRoutable) {
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
        router?.openAddAccount(candidates: candidatesSubject.value)
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

        wallets
            .map { wallet in
                wallet.accountModelsManager.accountModelsPublisher
                    .map(\.cryptoAccountsCount)
                    .removeDuplicates()
                    .map { FeedAccountCandidate(wallet: wallet, availability: Self.makeAvailability(cryptoAccountsCount: $0)) }
                    .eraseToAnyPublisher()
            }
            .combineLatest()
            .map { $0.filter(\.availability.isAvailable) }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, candidates in provider.candidatesSubject.send(candidates) }
            .store(in: &walletsBag)
    }

    static func makeAvailability(cryptoAccountsCount: Int) -> FeedAccountAvailability {
        let crypto = cryptoAccountsCount < AccountModelUtils.maxNumberOfAccounts

        return FeedAccountAvailability(crypto: crypto, joint: crypto && FeatureProvider.isAvailable(.jointAccounts))
    }
}
