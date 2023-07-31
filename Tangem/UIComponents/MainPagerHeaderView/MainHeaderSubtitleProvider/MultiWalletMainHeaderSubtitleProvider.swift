//
//  MultiWalletMainHeaderSubtitleProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MultiWalletMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        subtitleInfoSubject.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var containsSensitiveInfo: Bool { false }

    private var suffix: String {
        if userWalletModel.userWallet.isLocked {
            return separator + Localization.commonLocked
        }

        if userWalletModel.userWallet.card.wallets.contains(where: { $0.isImported ?? false }) {
            return separator + Localization.commonSeedPhrase
        }

        return ""
    }

    private let separator = " • "
    private let subtitleInfoSubject: CurrentValueSubject<MainHeaderSubtitleInfo, Never> = .init(.empty)
    private let userWalletModel: UserWalletModel
    private var updateSubscription: AnyCancellable?

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        formatSubtitle()
    }

    private func bind() {
        updateSubscription = userWalletModel.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.formatSubtitle()
            })
    }

    private func formatSubtitle() {
        let numberOfCards = userWalletModel.cardsCount
        let numberOfCardsPrefix = Localization.cardLabelCardCount(numberOfCards)
        let subtitle = numberOfCardsPrefix + suffix
        subtitleInfoSubject.send(.init(message: subtitle, formattingOption: .default))
    }
}
