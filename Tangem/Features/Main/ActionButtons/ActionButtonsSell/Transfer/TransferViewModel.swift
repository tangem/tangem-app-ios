//
//  TransferViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAccounts
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

final class TransferViewModel: ObservableObject {
    let title = Localization.actionbuttonTransferTitle
    let options: [TransferOption] = [.sell, .swap, .swapAndSend, .send]

    @Published private(set) var tokenInfoViewData: AddFundsTokenInfoView.ViewData

    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private let availabilityProvider: TokenActionAvailabilityProvider

    private weak var coordinator: TransferRoutable?

    private var bag = Set<AnyCancellable>()
    private var didTrackScreenOpened = false

    init(walletModel: any WalletModel, userWalletInfo: UserWalletInfo, coordinator: TransferRoutable) {
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
        self.coordinator = coordinator
        availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)

        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let badge = Self.makeAccountBadge(walletModel: walletModel, userWalletInfo: userWalletInfo)
        tokenInfoViewData = AddFundsTokenInfoView.ViewData(
            tokenIconInfo: tokenIconInfo,
            fiatBalance: walletModel.fiatTotalTokenBalanceProvider.formattedBalanceType.loadableTextViewState,
            cryptoBalance: walletModel.totalTokenBalanceProvider.formattedBalanceType.loadableTextViewState,
            badge: .account(badge)
        )

        bind()
    }

    func onAppear() {
        guard !didTrackScreenOpened else { return }
        didTrackScreenOpened = true
        // The transfer method screen is only reachable from the Main screen; Token uses its own actions sheet.
        Analytics.log(.transferMethodScreenOpened, params: [.source: .main])
    }

    @MainActor
    func userDidTap(_ option: TransferOption) {
        Analytics.log(option.analyticsEvent)

        switch option {
        case .sell:
            Task { @MainActor in coordinator?.transferRequestSell(walletModel: walletModel, userWalletInfo: userWalletInfo) }
        case .swap:
            Task { @MainActor in coordinator?.transferRequestSwap(walletModel: walletModel, userWalletInfo: userWalletInfo) }
        case .swapAndSend:
            Task { @MainActor in coordinator?.transferRequestSwapAndSend(walletModel: walletModel, userWalletInfo: userWalletInfo) }
        case .send:
            Task { @MainActor in coordinator?.transferRequestSend(walletModel: walletModel, userWalletInfo: userWalletInfo) }
        }
    }

    func isEnabled(_ option: TransferOption) -> Bool {
        switch option {
        // Sell/swap/swap-and-send follow the wallet features (`.exchange`/`.swapping`), so wallets that hide
        // them (e.g. Start2Coin) show the row disabled. Send stays gated by real send availability
        // (blocked on zero balance and other sending restrictions).
        case .sell: userWalletInfo.config.isFeatureVisible(.exchange)
        case .swap, .swapAndSend: userWalletInfo.config.isFeatureVisible(.swapping)
        case .send: availabilityProvider.isSendAvailable
        }
    }

    func close() {
        Task { @MainActor in coordinator?.transferClose() }
    }
}

// MARK: - Private

private extension TransferViewModel {
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

    static func makeAccountBadge(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo
    ) -> AddFundsTokenInfoView.AccountBadge {
        if let account = walletModel.account {
            return AddFundsTokenInfoView.AccountBadge(
                iconData: AccountModelUtils.UI.iconViewData(accountModel: account),
                name: account.name
            )
        }

        let letter = userWalletInfo.name.first.map(String.init) ?? ""
        return AddFundsTokenInfoView.AccountBadge(
            iconData: .composite(backgroundColor: Colors.Accounts.azureBlue, nameMode: .letter(letter)),
            name: userWalletInfo.name
        )
    }
}
