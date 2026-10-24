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
    let imageProvider: WalletImageProviding

    private let isUserWalletLocked: Bool
    private var bag: Set<AnyCancellable> = []

    convenience init(userWalletModel: UserWalletModel) {
        self.init(
            name: userWalletModel.name,
            subtitle: userWalletModel.cardSetLabel,
            imageProvider: userWalletModel.walletImageProvider,
            isUserWalletLocked: userWalletModel.isUserWalletLocked,
            totalBalancePublisher: userWalletModel.totalBalancePublisher
        )
    }

    init(
        name: String,
        subtitle: String,
        imageProvider: WalletImageProviding,
        isUserWalletLocked: Bool,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    ) {
        self.name = name
        self.subtitle = subtitle
        self.imageProvider = imageProvider
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
                imageProvider: CardImageProviderMock(),
                isUserWalletLocked: false,
                totalBalancePublisher: Just(.loaded(balance: 4496.75)).eraseToAnyPublisher()
            ),
            PromoCampaignEnrolledWalletViewModel(
                name: "Multi Card",
                subtitle: "1 card",
                imageProvider: CardImageProviderMock(),
                isUserWalletLocked: false,
                totalBalancePublisher: Just(.loaded(balance: 0.03)).eraseToAnyPublisher()
            ),
        ]
    }
}
