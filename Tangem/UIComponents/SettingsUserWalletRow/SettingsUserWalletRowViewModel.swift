//
//  SettingsUserWalletRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SettingsUserWalletRowViewModel: ObservableObject {
    @Published var name: String
    @Published var icon: LoadingValue<CardImageResult> = .loading
    @Published var cardsCount: String
    @Published var balanceState: LoadableTextView.State = .initialized
    let tapAction: () -> Void

    private let isUserWalletLocked: Bool
    private let totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never>
    private let cardImagePublisher: AnyPublisher<CardImageResult, Never>
    private var bag: Set<AnyCancellable> = []

    private let balanceFomatter = BalanceFormatter()

    convenience init(userWallet: UserWalletModel, tapAction: @escaping () -> Void) {
        self.init(
            name: userWallet.name,
            cardsCount: userWallet.cardsCount,
            isUserWalletLocked: userWallet.isUserWalletLocked,
            totalBalancePublisher: userWallet.totalBalancePublisher,
            cardImagePublisher: userWallet.cardImagePublisher,
            tapAction: tapAction
        )
    }
    
    init(
        name: String,
        cardsCount: Int,
        isUserWalletLocked: Bool,
        totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never>,
        cardImagePublisher: AnyPublisher<CardImageResult, Never>,
        tapAction: @escaping () -> Void
    ) {
        self.name = name
        self.cardsCount = Localization.cardLabelCardCount(cardsCount)
        self.isUserWalletLocked = isUserWalletLocked
        self.totalBalancePublisher = totalBalancePublisher
        self.cardImagePublisher = cardImagePublisher
        self.tapAction = tapAction
        bind()
    }

    func bind() {
        cardImagePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.icon = .loaded(result)
            }
            .store(in: &bag)

        totalBalancePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                guard !viewModel.isUserWalletLocked else {
                    viewModel.balanceState = .loaded(text: Localization.commonLocked)
                    return
                }

                switch result {
                case .loading:
                    viewModel.balanceState = .loading
                case .loaded(let totalBalance):
                    let formatted = viewModel.balanceFomatter.formatFiatBalance(totalBalance.balance)
                    viewModel.balanceState = .loaded(text: formatted)
                case .failedToLoad:
                    viewModel.balanceState = .loaded(text: Localization.commonUnreachable)
                }
            }
            .store(in: &bag)
    }
}
