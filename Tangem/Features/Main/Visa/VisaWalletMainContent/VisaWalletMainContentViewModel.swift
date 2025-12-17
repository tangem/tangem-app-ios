//
//  VisaWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import BlockchainSdk
import TangemVisa
import TangemLocalization
import TangemFoundation
import TangemUI
import struct TangemUIUtils.AlertBinder

protocol VisaWalletRoutable: AnyObject {
    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo])
    func openInSafari(url: URL)
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters)
    func openTransactionDetails(tokenItem: TokenItem, for record: VisaTransactionRecord, emailConfig: EmailConfig)
}

class VisaWalletMainContentViewModel: ObservableObject {
    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: any ExpressAvailabilityProvider

    @Published var balancesAndLimitsViewModel: VisaBalancesLimitsBottomSheetViewModel? = nil
    @Published var alert: AlertBinder? = nil

    @Published private(set) var transactionListViewState: TransactionsListView.State = .loading
    @Published private(set) var isTransactionHistoryReloading: Bool = true
    @Published private(set) var cryptoLimitText: String = ""
    @Published private(set) var numberOfDaysLimitText: String = ""
    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var failedToLoadInfoNotificationInput: NotificationViewInput?
    @Published private(set) var isScannerBusy: Bool = false
    @Published private(set) var isPaymentAccountLoaded: Bool = false
    @Published private(set) var buttons: [FixedSizeButtonWithIconInfo] = []

    var isBalancesAndLimitsBlockLoading: Bool {
        cryptoLimitText.isEmpty || numberOfDaysLimitText.isEmpty
    }

    private let visaWalletModel: VisaUserWalletModel
    private let tokenActionAvailabilityAlertBuilder = TokenActionAvailabilityAlertBuilder()
    private weak var coordinator: VisaWalletRoutable?
    private let buttonActionTypes: [TokenActionType] = [
        .receive,
        .buy,
    ]

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?

    init(
        visaWalletModel: VisaUserWalletModel,
        coordinator: VisaWalletRoutable?
    ) {
        self.visaWalletModel = visaWalletModel
        self.coordinator = coordinator

        setupButtons()
        bind()
    }

    func openBalancesAndLimits() {
        Analytics.log(.visaMainBalancesLimits)
        guard
            let balances = visaWalletModel.balances,
            let limit = visaWalletModel.limits?.currentLimit,
            let tokenItem = visaWalletModel.tokenItem
        else {
            return
        }

        balancesAndLimitsViewModel = .init(balances: balances, limit: limit, currencySymbol: tokenItem.currencySymbol)
    }

    func openExplorer() {
        guard let url = visaWalletModel.exploreURL() else {
            return
        }

        Analytics.log(.mainButtonExplore)
        coordinator?.openInSafari(url: url)
    }

    func exploreTransaction(with id: String) {
        guard
            let transactionId = UInt64(id),
            let transactionRecord = visaWalletModel.transaction(with: transactionId),
            let tokenItem = visaWalletModel.tokenItem,
            let emailConfig = visaWalletModel.emailConfig
        else {
            return
        }

        coordinator?.openTransactionDetails(tokenItem: tokenItem, for: transactionRecord, emailConfig: emailConfig)
    }

    func reloadTransactionHistory() {
        isTransactionHistoryReloading = true
        visaWalletModel.reloadHistory()
    }

    func fetchNextTransactionHistoryPage() -> FetchMore? {
        guard visaWalletModel.canFetchMoreTransactionHistory else {
            return nil
        }

        return FetchMore { [weak self] in
            self?.visaWalletModel.loadNextHistoryPage()
        }
    }

    func onPullToRefresh() async {
        guard updateTask == nil else {
            return
        }

        isTransactionHistoryReloading = true
        updateTask = runTask(in: self) { viewModel in
            await viewModel.visaWalletModel.generalUpdateAsync()
            try? await Task.sleep(for: .seconds(0.2))

            await runOnMain { viewModel.isTransactionHistoryReloading = false }

            viewModel.updateTask = nil
        }

        // Wait while the task is finished
        await updateTask?.value
    }

    private func bind() {
        visaWalletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { (self, newState) in
                self.setupButtons()
                switch newState {
                case .loading, .notInitialized:
                    return
                case .idle:
                    self.updateLimits()
                    self.setupNotifications(nil)
                case .failedToLoad(let error):
                    Analytics.log(event: .visaErrors, params: [
                        .errorCode: "\(error.universalErrorCode)",
                        .source: Analytics.ParameterValue.main.rawValue,
                    ])
                    self.setupNotifications(error)
                }
            }
            .store(in: &bag)

        visaWalletModel.transactionHistoryStatePublisher
            .receive(on: DispatchQueue.main)
            .filter { !$0.isLoading }
            .withWeakCaptureOf(self)
            .map { viewModel, newState in
                switch newState {
                case .initial, .loading:
                    return .loading
                case .loaded:
                    viewModel.isTransactionHistoryReloading = false
                    return .loaded(viewModel.visaWalletModel.transactionHistoryItems)
                case .failedToLoad(let error):
                    viewModel.isTransactionHistoryReloading = false
                    return .error(error)
                }
            }
            .assign(to: \.transactionListViewState, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func setupNotifications(_ modelError: VisaUserWalletModel.ModelError?) {
        guard let modelError else {
            failedToLoadInfoNotificationInput = nil
            return
        }

        switch modelError {
        case .missingValidRefreshToken:
            failedToLoadInfoNotificationInput = .init(
                style: .withButtons([.init(
                    action: weakify(self, forFunction: VisaWalletMainContentViewModel.notificationButtonTapped),
                    actionType: .unlock,
                    isWithLoader: true
                )]),
                severity: .info,
                settings: .init(event: VisaNotificationEvent.missingValidRefreshToken, dismissAction: nil)
            )
        default:
            failedToLoadInfoNotificationInput = NotificationsFactory().buildNotificationInput(for: modelError.notificationEvent)
        }
    }

    private func notificationButtonTapped(notificationId: NotificationViewId, buttonActionType: NotificationButtonActionType) {
        switch buttonActionType {
        case .unlock:
            isScannerBusy = true
            visaWalletModel.authorizeCard { [weak self] in
                DispatchQueue.main.async {
                    self?.isScannerBusy = false
                }
            }
        default:
            return
        }
    }

    private func updateLimits() {
        guard
            let limits = visaWalletModel.limits,
            let tokenItem = visaWalletModel.tokenItem
        else {
            return
        }

        let balanceFormatter = BalanceFormatter()
        let currentLimit = limits.currentLimit
        let remainingSummary = currentLimit.remainingOTPAmount ?? 0
        cryptoLimitText = balanceFormatter.formatCryptoBalance(remainingSummary, currencyCode: tokenItem.currencySymbol)

        let remainingTimeSeconds = Date().distance(to: currentLimit.actualExpirationDate)
        let remainingDays = Int(remainingTimeSeconds / 3600 / 24)
        numberOfDaysLimitText = Localization.visaLimitsAvailableForDaysTitle(remainingDays)
    }

    private func copyPaymentAccountAddress() {
        guard let accountAddress = visaWalletModel.accountAddress else {
            alert = ViewModelError.missingPaymentAccountInfo.alertBinder
            return
        }

        UIPasteboard.general.string = accountAddress
        let heavyImpaceGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpaceGenerator.impactOccurred()
        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }
}

// MARK: - Buttons setup logic

// [REDACTED_TODO_COMMENT]
// Extension will be changed, after `WalletModel` refactoring"
private extension VisaWalletMainContentViewModel {
    private func setupButtons() {
        let tokenActionInfo = try? makeTokenActionInfo()

        buttons = buttonActionTypes.map { action in
            let isActionButtonDisabled = isButtonDisabled(for: action, tokenActionInfo: tokenActionInfo)

            return FixedSizeButtonWithIconInfo(
                title: action.title,
                icon: action.icon,
                disabled: false,
                style: isActionButtonDisabled ? .disabled : .default,
                shouldShowBadge: false,
                action: { [weak self] in
                    self?.executeButtonAction(for: action)
                },
                longPressAction: makeLongTapAction(for: action)
            )
        }
    }

    private func isButtonDisabled(for actionType: TokenActionType, tokenActionInfo: TokenActionInfo?) -> Bool {
        guard let tokenActionInfo else {
            return true
        }

        switch actionType {
        case .receive:
            return false
        case .buy:
            // [REDACTED_TODO_COMMENT]
            // Use TokenActionAvailabilityProvider(userWalletConfig:, walletModel:) instead
            return !expressAvailabilityProvider.canOnramp(tokenItem: tokenActionInfo.tokenItem)
        default:
            return true
        }
    }

    private func executeButtonAction(for actionType: TokenActionType) {
        switch actionType {
        case .receive:
            openReceive()
        case .buy:
            openBuyCrypto()
        default:
            break
        }
    }

    private func makeLongTapAction(for actionType: TokenActionType) -> (() -> Void)? {
        switch actionType {
        case .receive:
            return weakify(self, forFunction: VisaWalletMainContentViewModel.copyPaymentAccountAddress)
        default:
            return nil
        }
    }

    private func makeTokenActionInfo() throws(ViewModelError) -> TokenActionInfo {
        switch visaWalletModel.currentModelState {
        case .notInitialized, .loading:
            throw .infoIsLoading
        case .failedToLoad, .idle:
            break
        }

        guard let accountAddress = visaWalletModel.accountAddress else {
            throw .missingPaymentAccountInfo
        }

        guard let tokenItem = visaWalletModel.tokenItem else {
            throw .missingTokenInfo
        }

        return .init(accountAddress: accountAddress, tokenItem: tokenItem)
    }
}

// MARK: - Buttons actions

// [REDACTED_TODO_COMMENT]
// Extension will be changed, after `WalletModel` refactoring"
private extension VisaWalletMainContentViewModel {
    func openReceive() {
        let info: TokenActionInfo
        do {
            info = try makeTokenActionInfo()
        } catch {
            alert = error.alertBinder
            return
        }

        Analytics.log(event: .buttonReceive, params: [
            .token: info.tokenItem.currencySymbol,
            .type: Analytics.ParameterValue.visa.rawValue,
        ])

        // Dummy address to use with `ReceiveBottomSheetUtils`
        let visaAddress = PlainAddress(
            value: info.accountAddress,
            publicKey: .init(seedKey: Data(), derivationType: nil),
            type: .default
        )
        let addressInfos = ReceiveAddressInfoUtils().makeAddressInfos(from: [visaAddress])

        coordinator?.openReceiveScreen(
            tokenItem: info.tokenItem,
            addressInfos: addressInfos
        )
    }

    func openBuyCrypto() {
        Analytics.log(.actionButtonsBuyButton, params: [.type: .visa])
        let info: TokenActionInfo
        do {
            info = try makeTokenActionInfo()
        } catch {
            alert = error.alertBinder
            return
        }

        if let disabledLocalizedReason = visaWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        // [REDACTED_TODO_COMMENT]
        // Use TokenActionAvailabilityProvider(userWalletConfig:, walletModel:) instead
        guard expressAvailabilityProvider.canOnramp(tokenItem: info.tokenItem) else {
            alert = tokenActionAvailabilityAlertBuilder.alert(
                for: TokenActionAvailabilityProvider
                    .BuyActionAvailabilityStatus
                    .unavailable(tokenName: info.tokenItem.name)
            )
            return
        }

        // [REDACTED_TODO_COMMENT]
        // Implement Onramp functionality with VisaWalletModel as WalletModel
        // coordinator?.openOnramp(userWalletModel:, walletModel:)
    }
}

private extension VisaWalletMainContentViewModel {
    enum ViewModelError: LocalizedError {
        case infoIsLoading
        case missingTokenInfo
        case missingPaymentAccountInfo

        var errorDescription: String? {
            switch self {
            case .infoIsLoading:
                return Localization.visaMainButtonAlertStillLoading
            case .missingTokenInfo:
                return Localization.visaMainButtonAlertMissingTokenInfo
            case .missingPaymentAccountInfo:
                return Localization.visaMainButtonAlertMissingPaymentAccountInfoMessage
            }
        }
    }
}

private extension VisaWalletMainContentViewModel {
    struct TokenActionInfo {
        let accountAddress: String
        let tokenItem: TokenItem
    }
}
