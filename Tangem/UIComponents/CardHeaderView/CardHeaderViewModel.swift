//
//  CardHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CardHeaderViewModel: ObservableObject {
    let cardImage: ImageType?
    let isCardLocked: Bool

    @Published private(set) var cardName: String = ""
    @Published private(set) var subtitleInfo: CardHeaderSubtitleInfo = .empty
    @Published private(set) var balance: NSAttributedString = .init(string: "")
    @Published var isLoadingFiatBalance: Bool = true
    @Published var isLoadingSubtitle: Bool = true
    @Published var showSensitiveInformation: Bool = true

    var showSensitiveSubtitleInformation: Bool {
        guard isSubtitleContainsSensitiveInformation else {
            return true
        }

        return showSensitiveInformation
    }

    private let isSubtitleContainsSensitiveInformation: Bool

    private let cardInfoProvider: CardHeaderInfoProvider
    private let cardSubtitleProvider: CardHeaderSubtitleProvider
    private let balanceProvider: TotalBalanceProviding

    private var bag: Set<AnyCancellable> = []

    init(
        cardInfoProvider: CardHeaderInfoProvider,
        cardSubtitleProvider: CardHeaderSubtitleProvider,
        balanceProvider: TotalBalanceProviding
    ) {
        self.cardInfoProvider = cardInfoProvider
        self.cardSubtitleProvider = cardSubtitleProvider
        self.balanceProvider = balanceProvider

        isCardLocked = cardInfoProvider.isCardLocked
        cardImage = cardInfoProvider.cardHeaderImage
        isSubtitleContainsSensitiveInformation = cardSubtitleProvider.containsSensitiveInfo
        bind()
    }

    private func bind() {
        cardInfoProvider.cardNamePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.cardName, on: self, ownership: .weak)
            .store(in: &bag)

        cardSubtitleProvider.isLoadingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoadingSubtitle, on: self, ownership: .weak)
            .store(in: &bag)

        cardSubtitleProvider.subtitlePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.subtitleInfo, on: self, ownership: .weak)
            .store(in: &bag)

        balanceProvider.totalBalancePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                if self?.cardInfoProvider.isCardLocked ?? false {
                    return
                }

                switch newValue {
                case .loading:
                    self?.isLoadingFiatBalance = true
                case .loaded(let balance):
                    self?.isLoadingFiatBalance = false

                    let balanceFormatter = BalanceFormatter()
                    let fiatBalanceFormatted = balanceFormatter.formatFiatBalance(balance.balance, formattingOptions: .defaultFiatFormattingOptions)
                    self?.balance = balanceFormatter.formatTotalBalanceForMain(fiatBalance: fiatBalanceFormatted, formattingOptions: .defaultOptions)
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load total balance. Reason: \(error)")
                    self?.isLoadingFiatBalance = false

                    self?.balance = NSAttributedString(string: BalanceFormatter.defaultEmptyBalanceString)
                }
            }
            .store(in: &bag)
    }
}
