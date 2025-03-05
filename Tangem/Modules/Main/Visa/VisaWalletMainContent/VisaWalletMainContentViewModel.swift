//
//  VisaWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemVisa
import UIKit

protocol VisaWalletRoutable: AnyObject {
    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo])
    func openInSafari(url: URL)
    func openBuyCrypto(at url: URL, action: @escaping () -> Void)
    func openTransactionDetails(tokenItem: TokenItem, for record: VisaTransactionRecord)
}

class VisaWalletMainContentViewModel: ObservableObject {
    @Published var balancesAndLimitsViewModel: VisaBalancesLimitsBottomSheetViewModel? = nil
    @Published var alert: AlertBinder? = nil

    @Published private(set) var transactionListViewState: TransactionsListView.State = .loading
    @Published private(set) var isTransactoinHistoryReloading: Bool = true
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
    private weak var coordinator: VisaWalletRoutable?
    private let buttonActionTypes: [TokenActionType] = [
        .receive,
        .buy,
    ]

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Error>?

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

        coordinator?.openInSafari(url: url)
    }

    func exploreTransaction(with id: String) {
        guard
            let transactionId = UInt64(id),
            let transactionRecord = visaWalletModel.transaction(with: transactionId),
            let tokenItem = visaWalletModel.tokenItem
        else {
            return
        }

        coordinator?.openTransactionDetails(tokenItem: tokenItem, for: transactionRecord)
    }

    func reloadTransactionHistory() {
        isTransactoinHistoryReloading = true
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

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        guard updateTask == nil else {
            return
        }

        isTransactoinHistoryReloading = true
        updateTask = Task { [weak self] in
            await self?.visaWalletModel.generalUpdateAsync()
            try await Task.sleep(seconds: 0.2)

            await runOnMain {
                self?.isTransactoinHistoryReloading = false
                completionHandler()
            }

            self?.updateTask = nil
        }
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
                case .failedToInitialize(let error):
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
                    viewModel.isTransactoinHistoryReloading = false
                    return .loaded(viewModel.visaWalletModel.transactionHistoryItems)
                case .failedToLoad(let error):
                    viewModel.isTransactoinHistoryReloading = false
                    return .error(error)
                }
            }
            .assign(to: \.transactionListViewState, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func setupNotifications(_ modelError: VisaUserWalletModel.ModelError) {
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
        numberOfDaysLimitText = "available for \(remainingDays) day(s)"
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
                longPressAction: longTapAction(for: action)
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
            return !tokenActionInfo.exchangeUtility.buyAvailable || tokenActionInfo.exchangeUtility.buyURL == nil
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

    private func longTapAction(for actionType: TokenActionType) -> (() -> Void)? {
        switch actionType {
        case .receive:
            return weakify(self, forFunction: VisaWalletMainContentViewModel.copyPaymentAccountAddress)
        default:
            return nil
        }
    }

    private func makeTokenActionInfo() throws (ViewModelError) -> TokenActionInfo {
        switch visaWalletModel.currentModelState {
        case .notInitialized, .loading:
            throw .infoIsLoading
        case .failedToInitialize, .idle:
            break
        }

        guard let accountAddress = visaWalletModel.accountAddress else {
            throw .missingPaymentAccountInfo
        }

        guard let tokenItem = visaWalletModel.tokenItem else {
            throw .missingTokenInfo
        }

        let exchangeCryptoUtility = ExchangeCryptoUtility(
            blockchain: tokenItem.blockchain,
            address: accountAddress,
            amountType: tokenItem.amountType
        )

        return .init(
            accountAddress: accountAddress,
            tokenItem: tokenItem,
            exchangeUtility: exchangeCryptoUtility
        )
    }
}

// MARK: - Buttons actions

// [REDACTED_TODO_COMMENT]
private extension VisaWalletMainContentViewModel {
    func openReceive() {
        let info: TokenActionInfo
        do {
            info = try makeTokenActionInfo()
        } catch {
            alert = error.alertBinder
            return
        }

        Analytics.log(event: .buttonReceive, params: [.token: info.tokenItem.currencySymbol])

        let addressType = AddressType.default
        let addressInfo = ReceiveAddressInfo(
            address: info.accountAddress,
            type: addressType,
            localizedName: addressType.defaultLocalizedName,
            addressQRImage: QrCodeGenerator.generateQRCode(from: info.accountAddress)
        )
        coordinator?.openReceiveScreen(
            tokenItem: info.tokenItem,
            addressInfos: [addressInfo]
        )
    }

    func openBuyCrypto() {
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

        guard
            info.exchangeUtility.buyAvailable,
            let url = info.exchangeUtility.buyURL
        else {
            alert = SingleTokenAlertBuilder().buyUnavailableAlert(for: info.tokenItem)
            return
        }

        coordinator?.openBuyCrypto(at: url, action: { [weak self] in
            self?.onPullToRefresh(completionHandler: {})
        })
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
                return "Information is still loading, please wait"
            case .missingTokenInfo:
                return "Unable to load information about"
            case .missingPaymentAccountInfo:
                return "Missing Payment account information. Please contact support"
            }
        }
    }
}

private extension VisaWalletMainContentViewModel {
    struct TokenActionInfo {
        let accountAddress: String
        let tokenItem: TokenItem
        let exchangeUtility: ExchangeCryptoUtility
    }
}
