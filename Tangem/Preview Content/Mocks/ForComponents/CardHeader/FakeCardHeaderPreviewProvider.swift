//
//  FakeCardHeaderPreviewProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class FakeCardHeaderPreviewProvider: ObservableObject {
    @Published var models: [MultiWalletCardHeaderViewModel] = []

    let infoProviders = [
        CardInfoProvider(
            cardName: "William Wallet",
            numberOfCards: 3,
            cardImage: Assets.Cards.wallet2Triple,
            isWalletImported: true,
            tapAction: { provider in
                provider.cardName = provider.cardName == "William Wallet" ? "Uilleam Uallet" : "William Wallet"
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: 4346437892534324.2189,
                        currencyCode: "USD",
                        hasError: false
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),

        CardInfoProvider(
            cardName: "Wallet 2 Twins",
            numberOfCards: 2,
            cardImage: Assets.Cards.wallet2Double,
            isWalletImported: true,
            tapAction: { provider in
                provider.cardName = provider.cardName == "Wallet Hannah" ? "Wallet Jane" : "Wallet Hannah"
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: 92324.2133654889,
                        currencyCode: "EUR",
                        hasError: false
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),

        CardInfoProvider(
            cardName: "Plain Old Wallet wallet wallet wallet wallet wallet wallet",
            numberOfCards: 2,
            cardImage: Assets.Cards.wallet,
            isWalletImported: true,
            tapAction: { provider in
                provider.cardName = provider.cardName == "POWwwwwwww" ? "Plain Old Wallet wallet wallet wallet wallet wallet wallet" : "POWwwwwwww"
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: 0.0,
                        currencyCode: "EUR",
                        hasError: false
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),

        CardInfoProvider(
            cardName: "Note",
            numberOfCards: 1,
            cardImage: Assets.Cards.noteDoge,
            isWalletImported: false,
            tapAction: { provider in
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: nil,
                        currencyCode: "RUB",
                        hasError: true
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),

        CardInfoProvider(
            cardName: "BTC bird",
            numberOfCards: 1,
            cardImage: nil,
            isWalletImported: false,
            tapAction: { provider in
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: 454.2114313,
                        currencyCode: "USD",
                        hasError: false
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),

        CardInfoProvider(
            cardName: "BTC bird kookee kookee kookoo-kooroo-kookoo kookoo-kooroo-kookoo kookee kookee",
            numberOfCards: 1,
            cardImage: nil,
            isWalletImported: false,
            tapAction: { provider in
                switch provider.balance {
                case .loading:
                    provider.balance = .loaded(TotalBalanceProvider.TotalBalance(
                        balance: 4567575476468896456534878754.2114313,
                        currencyCode: "USD",
                        hasError: false
                    ))
                case .loaded, .failedToLoad:
                    provider.balance = .loading
                }
            }
        ),
    ]

    init() {
        initializeModels()
    }

    private func initializeModels() {
        models = infoProviders.map {
            .init(cardInfoProvider: $0, balanceProvider: $0)
        }
    }
}

extension FakeCardHeaderPreviewProvider {
    final class CardInfoProvider: MultiWalletCardHeaderInfoProvider, TotalBalanceProviding {
        @Published var cardName: String
        @Published var numberOfCards: Int
        @Published var balance: LoadingValue<TotalBalanceProvider.TotalBalance> = .loading

        let cardImage: ImageType?

        var tapAction: (CardInfoProvider) -> Void

        private(set) var isWalletImported: Bool

        var cardNamePublisher: AnyPublisher<String, Never> { $cardName.eraseToAnyPublisher() }

        var numberOfCardsPublisher: AnyPublisher<Int, Never> { $numberOfCards.eraseToAnyPublisher() }

        init(cardName: String, numberOfCards: Int, cardImage: ImageType?, isWalletImported: Bool, tapAction: @escaping (CardInfoProvider) -> Void) {
            self.cardName = cardName
            self.numberOfCards = numberOfCards
            self.cardImage = cardImage
            self.isWalletImported = isWalletImported

            self.tapAction = tapAction
        }

        func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
            $balance.eraseToAnyPublisher()
        }
    }
}
