//
//  AddFundsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI

final class AddFundsViewModel: ObservableObject, FloatingSheetContentViewModel {
    let mode: Mode
    let primaryAction: PrimaryAction
    let title: String
    let options: [AddFundsOptionView.Option] = [.buy, .swap, .receive]

    let isRedesign: Bool = FeatureProvider.isAvailable(.redesign)

    // Available-balance data for the legacy (non-redesign) layout.
    let tokenIconInfo: TokenIconInfo
    let fiatBalanceText: String
    let cryptoBalanceText: String

    @Published private(set) var tokenInfoViewData: AddFundsTokenInfoView.ViewData
    @Published private(set) var accountBadge: AddFundsTokenInfoView.AccountBadge

    private let walletModel: any WalletModel
    private let userWalletModel: any UserWalletModel

    private weak var coordinator: AddFundsRoutable?

    private var bag = Set<AnyCancellable>()

    init(input: Input, coordinator: AddFundsRoutable) {
        mode = input.mode
        primaryAction = input.primaryAction
        walletModel = input.walletModel
        userWalletModel = input.userWalletModel
        self.coordinator = coordinator

        title = input.walletModel.tokenItem.name

        let tokenIconInfo = TokenIconInfoBuilder().build(from: input.walletModel.tokenItem, isCustom: input.walletModel.isCustom)
        self.tokenIconInfo = tokenIconInfo

        let formatter = BalanceFormatter()
        fiatBalanceText = formatter.formatFiatBalance(input.walletModel.fiatAvailableBalanceProvider.balanceType.value)
        cryptoBalanceText = formatter.formatCryptoBalance(
            input.walletModel.availableBalanceProvider.balanceType.value,
            currencyCode: input.walletModel.tokenItem.currencySymbol
        )

        let badge = Self.makeAccountBadge(walletModel: input.walletModel, userWalletModel: input.userWalletModel)
        accountBadge = badge
        tokenInfoViewData = AddFundsTokenInfoView.ViewData(
            tokenIconInfo: tokenIconInfo,
            fiatBalance: input.walletModel.fiatTotalTokenBalanceProvider.formattedBalanceType.value,
            cryptoBalance: input.walletModel.totalTokenBalanceProvider.formattedBalanceType.value,
            accountBadge: badge
        )

        bind()
    }

    func userDidTap(_ option: AddFundsOptionView.Option) {
        switch option {
        case .buy:
            Analytics.log(.addFundsButtonBuy)
            Task { @MainActor in
                coordinator?.addFundsRequestBuy(walletModel: walletModel, userWalletModel: userWalletModel)
            }
        case .swap:
            Analytics.log(.addFundsButtonSwap)
            Task { @MainActor in
                coordinator?.addFundsRequestSwap(walletModel: walletModel, userWalletModel: userWalletModel)
            }
        case .receive:
            Analytics.log(.addFundsButtonReceive)
            let receiveViewModel = AvailabilityReceiveFlowFactory(
                flow: .crypto,
                tokenItem: walletModel.tokenItem,
                addressTypesProvider: walletModel
            ).makeAvailabilityReceiveFlow()
            Task { @MainActor in
                coordinator?.addFundsRequestReceive(viewModel: receiveViewModel)
            }
        }
    }

    func userDidTapPrimary() {
        switch primaryAction {
        case .close:
            close()
        case .goToToken:
            userDidTapGoToToken()
        }
    }

    func userDidTapGoToToken() {
        Analytics.log(.addFundsButtonGoToToken)
        Task { @MainActor in
            coordinator?.addFundsRequestGoToToken(walletModel: walletModel, userWalletModel: userWalletModel)
        }
    }

    func userDidTapBack() {
        Task { @MainActor in
            coordinator?.addFundsClose()
        }
    }

    func close() {
        Task { @MainActor in
            coordinator?.addFundsClose()
        }
    }
}

// MARK: - Private

private extension AddFundsViewModel {
    func bind() {
        Publishers.CombineLatest(
            walletModel.fiatTotalTokenBalanceProvider.formattedBalanceTypePublisher,
            walletModel.totalTokenBalanceProvider.formattedBalanceTypePublisher
        )
        .receiveOnMain()
        .sink { [weak self] fiat, crypto in
            guard let self else { return }
            tokenInfoViewData = AddFundsTokenInfoView.ViewData(
                tokenIconInfo: tokenInfoViewData.tokenIconInfo,
                fiatBalance: fiat.value,
                cryptoBalance: crypto.value,
                accountBadge: tokenInfoViewData.accountBadge
            )
        }
        .store(in: &bag)
    }

    static func makeAccountBadge(
        walletModel: any WalletModel,
        userWalletModel: any UserWalletModel
    ) -> AddFundsTokenInfoView.AccountBadge {
        if let account = walletModel.account {
            return AddFundsTokenInfoView.AccountBadge(
                iconData: AccountModelUtils.UI.iconViewData(accountModel: account),
                name: account.name
            )
        }

        let letter = userWalletModel.name.first.map(String.init) ?? ""
        return AddFundsTokenInfoView.AccountBadge(
            iconData: .composite(backgroundColor: Colors.Accounts.azureBlue, nameMode: .letter(letter)),
            name: userWalletModel.name
        )
    }
}

// MARK: - Input / Mode / PrimaryAction

extension AddFundsViewModel {
    struct Input {
        let mode: Mode
        let primaryAction: PrimaryAction
        let walletModel: any WalletModel
        let userWalletModel: any UserWalletModel
    }

    enum Mode: Equatable {
        case sheet(SheetSize)
        case stack
    }

    enum SheetSize: Equatable {
        case compact
        case full
    }

    enum PrimaryAction: Equatable {
        /// Dismiss the screen. Title is provided by the caller.
        case close(title: String)
        /// Push TokenDetails for the same wallet model.
        case goToToken
    }
}
