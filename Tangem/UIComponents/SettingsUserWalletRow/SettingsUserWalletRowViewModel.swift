//
//  SettingsUserWalletRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import TangemFoundation
import TangemUI

final class SettingsUserWalletRowViewModel: ObservableObject, Identifiable {
    @Published var name: String = ""
    @Published var icon: UserWalletIcon
    @Published var cardSetLabel: String
    @Published var hasSeedPhrase: Bool
    @Published var isUserWalletBackupNeeded: Bool
    @Published var balanceState: LoadableBalanceView.State = .loading()
    let tapAction: () -> Void

    let isUserWalletLocked: Bool
    private let userWalletUpdatePublisher: AnyPublisher<UpdateResult, Never>
    private let totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    private var bag: Set<AnyCancellable> = []

    convenience init(userWallet: UserWalletModel, tapAction: @escaping () -> Void) {
        self.init(
            name: userWallet.name,
            cardSetLabel: userWallet.config.cardSetLabel,
            hasSeedPhrase: Self.hasSeedPhrase(for: userWallet),
            isUserWalletBackupNeeded: MobileBackupStatusUtil(userWalletModel: userWallet).isBackupNeeded,
            isUserWalletLocked: userWallet.isUserWalletLocked,
            userWalletUpdatePublisher: userWallet.updatePublisher,
            totalBalancePublisher: userWallet.totalBalancePublisher,
            icon: userWallet.walletIcon,
            tapAction: tapAction
        )
    }

    init(
        name: String,
        cardSetLabel: String,
        hasSeedPhrase: Bool,
        isUserWalletBackupNeeded: Bool,
        isUserWalletLocked: Bool,
        userWalletUpdatePublisher: AnyPublisher<UpdateResult, Never>,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>,
        icon: UserWalletIcon,
        tapAction: @escaping () -> Void
    ) {
        self.name = name
        self.cardSetLabel = cardSetLabel
        self.hasSeedPhrase = hasSeedPhrase
        self.isUserWalletBackupNeeded = isUserWalletBackupNeeded
        self.isUserWalletLocked = isUserWalletLocked
        self.userWalletUpdatePublisher = userWalletUpdatePublisher
        self.totalBalancePublisher = totalBalancePublisher
        self.icon = icon
        self.tapAction = tapAction
        bind()
    }

    func bind() {
        userWalletUpdatePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                switch event {
                case .nameDidChange(let name):
                    viewModel.name = name
                case .configurationChanged(let model):
                    viewModel.cardSetLabel = model.config.cardSetLabel
                    viewModel.hasSeedPhrase = Self.hasSeedPhrase(for: model)
                    if case .configurationChanged(let model) = event {
                        viewModel.isUserWalletBackupNeeded = MobileBackupStatusUtil(userWalletModel: model).isBackupNeeded
                        viewModel.icon = model.walletIcon
                    }
                }
            }
            .store(in: &bag)

        totalBalancePublisher
            .withAppCurrencyCode()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (state, currencyCode) = input
                viewModel.setupBalanceState(state: state, currencyCode: currencyCode)
            }
            .store(in: &bag)
    }

    private static func hasSeedPhrase(for userWallet: UserWalletModel) -> Bool {
        if userWallet.config.productType == .mobileWallet {
            return MobileBackupStatusUtil(userWalletModel: userWallet).hasMnemonicBackup
        }

        return userWallet.hasImportedWallets
    }

    private func setupBalanceState(state: TotalBalanceState, currencyCode: String) {
        guard !isUserWalletLocked else {
            balanceState = .loaded(text: Localization.commonLocked)
            return
        }

        balanceState = LoadableBalanceViewStateBuilder().buildTotalBalance(state: state, currencyCode: currencyCode)
    }
}
