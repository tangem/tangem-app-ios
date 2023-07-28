//
//  LockedUserWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LockedUserWallet: UserWalletModel {
    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    let userTokenListManager: UserTokenListManager = LockedUserTokenListManager()
    var signer: TangemSigner

    var tokensCount: Int? { nil }

    var cardsCount: Int { config.cardsCount }

    var isMultiWallet: Bool { config.hasFeature(.multiCurrency) }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var updatePublisher: AnyPublisher<Void, Never> { .just }

    private(set) var userWallet: UserWallet

    private let config: UserWalletConfig
    private let cardNameSubject: CurrentValueSubject<String, Never>

    private var bag = Set<AnyCancellable>()

    init(with userWallet: UserWallet) {
        self.userWallet = userWallet
        cardNameSubject = .init(userWallet.name)
        config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
        signer = TangemSigner(with: userWallet.card.cardId, sdk: config.makeTangemSdk())
    }

    func initialUpdate() {}

    func updateWalletName(_ name: String) {
        cardNameSubject.send(name)
    }

    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        .just(output: .loaded(.init(balance: 0, currencyCode: "", hasError: false)))
    }

    private func bind() {
        cardNameSubject
            .sink { [weak self] newName in
                self?.userWallet.name = newName
            }
            .store(in: &bag)
    }
}

extension LockedUserWallet: CardHeaderInfoProvider {
    var isCardLocked: Bool { true }

    var cardNamePublisher: AnyPublisher<String, Never> {
        cardNameSubject.eraseToAnyPublisher()
    }

    var cardImage: ImageType? {
        nil
    }
}
