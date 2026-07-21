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
import TangemUIUtils

final class TransferViewModel: ObservableObject {
    let title = Localization.actionbuttonTransferTitle
    let options: [TransferOption] = [.send, .swap, .swapAndSend, .sell]

    @Published private(set) var tokenInfoViewData: AddFundsTokenInfoView.ViewData?

    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo

    private let tokenIconInfo: TokenIconInfo
    private let availabilityProvider: TokenActionAvailabilityProvider

    private weak var coordinator: TransferRoutable?

    private var didTrackScreenOpened = false

    init(walletModel: any WalletModel, userWalletInfo: UserWalletInfo, coordinator: TransferRoutable) {
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
        self.coordinator = coordinator
        tokenIconInfo = Self.makeTokenIconInfo(walletModel: walletModel)
        availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)
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
            guard availabilityProvider.isSellAvailable else {
                showUnavailabilityAlert(for: option)
                return
            }
            Task { @MainActor in coordinator?.transferRequestSell(walletModel: walletModel, userWalletInfo: userWalletInfo) }
        case .swap:
            Task { @MainActor in coordinator?.transferRequestSwap(walletModel: walletModel, userWalletInfo: userWalletInfo) }
        case .swapAndSend:
            Task { @MainActor in coordinator?.transferRequestSwapAndSend(walletModel: walletModel, userWalletInfo: userWalletInfo) }
        case .send:
            guard availabilityProvider.isSendAvailable else {
                showUnavailabilityAlert(for: option)
                return
            }
            Task { @MainActor in coordinator?.transferRequestSend(walletModel: walletModel, userWalletInfo: userWalletInfo) }
        }
    }

    func isEnabled(_ option: TransferOption) -> Bool {
        switch option {
        case .sell: userWalletInfo.config.isFeatureVisible(.exchange)
        case .swap, .swapAndSend: userWalletInfo.config.isFeatureVisible(.swapping)
        case .send: true
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
        .withWeakCaptureOf(self)
        .map { viewModel, balanceTypes in
            let (fiatBalanceType, cryptoBalanceType) = balanceTypes
            return viewModel.makeTokenInfoViewData(
                fiatBalanceType: fiatBalanceType,
                cryptoBalanceType: cryptoBalanceType
            )
        }
        .assign(to: &$tokenInfoViewData)
    }

    func makeTokenInfoViewData(
        fiatBalanceType: FormattedTokenBalanceType,
        cryptoBalanceType: FormattedTokenBalanceType
    ) -> AddFundsTokenInfoView.ViewData {
        let badge = makeBadge()

        return AddFundsTokenInfoView.ViewData(
            tokenIconInfo: tokenIconInfo,
            fiatBalance: fiatBalanceType.loadableTextViewState,
            cryptoBalance: cryptoBalanceType.loadableTextViewState,
            badge: badge
        )
    }

    func makeBadge() -> AddFundsTokenInfoView.Badge? {
        let unlockedWallets = userWalletRepository.models.filter { !$0.isUserWalletLocked }
        let hasMultipleAccounts = unlockedWallets.contains {
            $0.accountModelsManager.accountModels.cryptoAccounts().hasMultipleAccounts
        }

        if hasMultipleAccounts {
            let accountBadge = makeAccountBadge()
            return .account(accountBadge)
        }

        let hasMultipleWallets = unlockedWallets.count > 1

        if hasMultipleWallets {
            let walletBadge = makeWalletBadge()
            return .wallet(walletBadge)
        }

        return nil
    }

    func makeAccountBadge() -> AddFundsTokenInfoView.AccountBadge {
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

    func makeWalletBadge() -> AddFundsTokenInfoView.WalletBadge {
        AddFundsTokenInfoView.WalletBadge(
            thumbnail: userWalletInfo.config.walletThumbnailType,
            name: userWalletInfo.name
        )
    }

    @MainActor
    func showUnavailabilityAlert(for option: TransferOption) {
        let builder = TokenActionAvailabilityAlertBuilder()

        let alert: AlertBinder? = switch option {
        case .send: builder.alert(for: availabilityProvider.sendAvailability)
        case .sell: builder.alert(for: availabilityProvider.sellAvailability)
        case .swap, .swapAndSend: nil
        }

        if let alert {
            alertPresenter.present(alert: alert)
        }
    }

    static func makeTokenIconInfo(walletModel: any WalletModel) -> TokenIconInfo {
        TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }
}
