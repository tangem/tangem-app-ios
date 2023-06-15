//
//  MultiWalletCardHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MultiWalletCardHeaderViewModel: ObservableObject {
    let isWalletImported: Bool
    let cardImage: ImageType?

    @Published private(set) var cardName: String = ""
    @Published private(set) var numberOfCards: String = ""
    @Published private(set) var balance: NSAttributedString = .init(string: "")
    @Published var isLoadingBalance: Bool = true
    @Published var showSensitiveInformation: Bool = true

    var isWithCardImage: Bool { cardImage != nil }

    private let cardInfoProvider: MultiWalletCardHeaderInfoProvider
    private let balanceProvider: TotalBalanceProviding

    private var bag: Set<AnyCancellable> = []

    init(
        cardInfoProvider: MultiWalletCardHeaderInfoProvider,
        balanceProvider: TotalBalanceProviding
    ) {
        self.cardInfoProvider = cardInfoProvider
        self.balanceProvider = balanceProvider

        isWalletImported = cardInfoProvider.isWalletImported
        cardImage = cardInfoProvider.cardImage
        bind()
    }

    private func bind() {
        cardInfoProvider.cardNamePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.cardName, on: self)
            .store(in: &bag)

        cardInfoProvider.numberOfCardsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] numberOfCards in
                self?.numberOfCards = Localization.cardLabelCardCount(numberOfCards)
            }
            .store(in: &bag)

        balanceProvider.totalBalancePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                switch newValue {
                case .loading:
                    self?.isLoadingBalance = true
                case .loaded(let balance):
                    self?.isLoadingBalance = false

                    let balanceFormatter = BalanceFormatter()
                    let fiatBalanceFormatted = balanceFormatter.formatFiatBalance(balance.balance, formattingOptions: .defaultFiatFormattingOptions)
                    self?.balance = balanceFormatter.formatTotalBalanceForMain(fiatBalance: fiatBalanceFormatted, formattingOptions: .defaultOptions)
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load total balance. Reason: \(error)")
                    self?.isLoadingBalance = false

                    self?.balance = NSAttributedString(string: BalanceFormatter.defaultEmptyBalanceString)
                }
            }
            .store(in: &bag)
    }
}
