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

    var showsBackButton: Bool { onBack != nil }

    let isRedesign: Bool = FeatureProvider.isAvailable(.redesign)

    // Available-balance data for the legacy (non-redesign) layout.
    let tokenIconInfo: TokenIconInfo
    let fiatBalanceText: String
    let cryptoBalanceText: String

    @Published private(set) var tokenInfoViewData: AddFundsTokenInfoView.ViewData

    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private let walletModel: any WalletModel
    private let userWalletModel: any UserWalletModel

    private let onBack: (() -> Void)?

    private weak var coordinator: AddFundsRoutable?

    private var bag = Set<AnyCancellable>()

    init(input: Input, coordinator: AddFundsRoutable) {
        mode = input.mode
        primaryAction = input.primaryAction
        walletModel = input.walletModel
        userWalletModel = input.userWalletModel
        onBack = input.onBack
        self.coordinator = coordinator

        title = Self.makeTitle(tokenItem: input.walletModel.tokenItem)

        let tokenIconInfo = TokenIconInfoBuilder().build(from: input.walletModel.tokenItem, isCustom: input.walletModel.isCustom)
        self.tokenIconInfo = tokenIconInfo

        let formatter = BalanceFormatter()
        fiatBalanceText = formatter.formatFiatBalance(input.walletModel.fiatAvailableBalanceProvider.balanceType.value)
        cryptoBalanceText = formatter.formatCryptoBalance(
            input.walletModel.availableBalanceProvider.balanceType.value,
            currencyCode: input.walletModel.tokenItem.currencySymbol
        )

        let badge = Self.makeBadge(walletModel: input.walletModel, userWalletModel: input.userWalletModel)
        tokenInfoViewData = AddFundsTokenInfoView.ViewData(
            tokenIconInfo: tokenIconInfo,
            fiatBalance: input.walletModel.fiatTotalTokenBalanceProvider.formattedBalanceType.loadableTextViewState,
            cryptoBalance: input.walletModel.totalTokenBalanceProvider.formattedBalanceType.loadableTextViewState,
            badge: badge
        )

        bind()
    }

    func userDidTap(_ option: AddFundsOptionView.Option) {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletInfo: userWalletModel.userWalletInfo,
            walletModel: walletModel
        )
        let availabilityAlertBuilder = TokenActionAvailabilityAlertBuilder()

        switch option {
        case .buy:
            if let unavailableAlert = availabilityAlertBuilder.alert(for: availabilityProvider.buyAvailablity) {
                alertPresenter.present(alert: unavailableAlert)
                return
            }

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
            if let unavailableAlert = availabilityAlertBuilder.alert(
                for: availabilityProvider.receiveAvailability,
                blockchain: walletModel.tokenItem.blockchain
            ) {
                alertPresenter.present(alert: unavailableAlert)
                return
            }

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

    func isEnabled(_ option: AddFundsOptionView.Option) -> Bool {
        switch option {
        // `.exchange` is the config feature that gates buy/sell (onramp/offramp) — there is no separate
        // buy feature. Not to be confused with the `.exchange` token action, which is swap.
        case .buy: userWalletModel.config.isFeatureVisible(.exchange)
        case .swap: userWalletModel.config.isFeatureVisible(.swapping)
        case .receive: true
        }
    }

    func userDidTapPrimary() {
        switch primaryAction {
        case .close:
            close()
        case .goToToken:
            userDidTapGoToToken()
        case .hidden:
            break
        }
    }

    func userDidTapGoToToken() {
        Analytics.log(.addFundsButtonGoToToken)
        Task { @MainActor in
            coordinator?.addFundsRequestGoToToken(walletModel: walletModel, userWalletModel: userWalletModel)
        }
    }

    func userDidTapBack() {
        onBack?()
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
                fiatBalance: fiat.loadableTextViewState,
                cryptoBalance: crypto.loadableTextViewState,
                badge: tokenInfoViewData.badge
            )
        }
        .store(in: &bag)
    }

    static func makeTitle(tokenItem: TokenItem) -> String {
        return Localization.commonGet + " " + tokenItem.name
    }

    static func makeBadge(
        walletModel: any WalletModel,
        userWalletModel: any UserWalletModel
    ) -> AddFundsTokenInfoView.Badge? {
        let hasMultipleAccounts = userWalletModel.accountModelsManager.accountModels.cryptoAccounts().hasMultipleAccounts

        if hasMultipleAccounts, let account = walletModel.account {
            return .account(AddFundsTokenInfoView.AccountBadge(
                iconData: AccountModelUtils.UI.iconViewData(accountModel: account),
                name: account.name
            ))
        }

        let hasMultipleWallets = InjectedValues[\.userWalletRepository].models.count > 1

        guard hasMultipleWallets else {
            return nil
        }

        return .wallet(AddFundsTokenInfoView.WalletBadge(
            thumbnail: userWalletModel.config.walletThumbnailType,
            name: userWalletModel.name
        ))
    }
}

// MARK: - Input / Mode / PrimaryAction

extension AddFundsViewModel {
    struct Input {
        let mode: Mode
        let primaryAction: PrimaryAction
        let walletModel: any WalletModel
        let userWalletModel: any UserWalletModel
        let onBack: (() -> Void)?

        init(
            mode: Mode,
            primaryAction: PrimaryAction,
            walletModel: any WalletModel,
            userWalletModel: any UserWalletModel,
            onBack: (() -> Void)? = nil
        ) {
            self.mode = mode
            self.primaryAction = primaryAction
            self.walletModel = walletModel
            self.userWalletModel = userWalletModel
            self.onBack = onBack
        }
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
        /// Don't show the primary button at all.
        case hidden
    }
}
