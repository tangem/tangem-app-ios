//
//  PromoCampaignEnrolledWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemUI

final class PromoCampaignEnrolledWalletViewModel: ObservableObject, Identifiable {
    @Published private(set) var balanceState: LoadableBalanceView.State = .loading()

    let name: String
    let subtitle: String
    let walletIcon: UserWalletIcon

    private let isUserWalletLocked: Bool
    private var bag: Set<AnyCancellable> = []

    convenience init(userWalletModel: UserWalletModel) {
        self.init(
            name: userWalletModel.name,
            subtitle: userWalletModel.cardSetLabel,
            walletIcon: userWalletModel.walletIcon,
            isUserWalletLocked: userWalletModel.isUserWalletLocked,
            totalBalancePublisher: userWalletModel.totalBalancePublisher
        )
    }

    init(
        name: String,
        subtitle: String,
        walletIcon: UserWalletIcon,
        isUserWalletLocked: Bool,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    ) {
        self.name = name
        self.subtitle = subtitle
        self.walletIcon = walletIcon
        self.isUserWalletLocked = isUserWalletLocked
        bind(totalBalancePublisher: totalBalancePublisher)
    }

    private func bind(totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>) {
        totalBalancePublisher
            .withAppCurrencyCode()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (state, currencyCode) = input
                viewModel.setupBalanceState(state: state, currencyCode: currencyCode)
            }
            .store(in: &bag)
    }

    private func setupBalanceState(state: TotalBalanceState, currencyCode: String) {
        guard !isUserWalletLocked else {
            balanceState = .loaded(text: Localization.commonLocked)
            return
        }

        balanceState = LoadableBalanceViewStateBuilder().buildTotalBalance(state: state, currencyCode: currencyCode)
    }
}

// MARK: - Previews

extension PromoCampaignEnrolledWalletViewModel {
    static var previewWallets: [PromoCampaignEnrolledWalletViewModel] {
        [
            PromoCampaignEnrolledWalletViewModel(
                name: "Main wallet",
                subtitle: "3 cards",
                walletIcon: .loadable(CardImageProviderMock()),
                isUserWalletLocked: false,
                totalBalancePublisher: Just(.loaded(balance: 4496.75)).eraseToAnyPublisher()
            ),
            PromoCampaignEnrolledWalletViewModel(
                name: "Multi Card",
                subtitle: "1 card",
                walletIcon: .loadable(CardImageProviderMock()),
                isUserWalletLocked: false,
                totalBalancePublisher: Just(.loaded(balance: 0.03)).eraseToAnyPublisher()
            ),
        ]
    }
}
