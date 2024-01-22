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

protocol VisaWalletRoutable: AnyObject {
    func openReceiveScreen(amountType: Amount.AmountType, blockchain: Blockchain, addressInfos: [ReceiveAddressInfo])
    func openExplorer(at url: URL, blockchainDisplayName: String)
}

class VisaWalletMainContentViewModel: ObservableObject {
    @Published var balancesAndLimitsViewModel: VisaBalancesLimitsBottomSheetViewModel? = nil

    @Published private(set) var transactionListViewState: TransactionsListView.State = .loading
    @Published private(set) var isTransactoinHistoryReloading: Bool = true
    @Published private(set) var cryptoLimitText: String = ""
    @Published private(set) var numberOfDaysLimitText: String = ""
    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var failedToLoadInfoNotificationInput: NotificationViewInput?

    var isBalancesAndLimitsBlockLoading: Bool {
        cryptoLimitText.isEmpty || numberOfDaysLimitText.isEmpty
    }

    private let visaWalletModel: VisaWalletModel
    private unowned let coordinator: VisaWalletRoutable

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Never>?

    init(
        visaWalletModel: VisaWalletModel,
        coordinator: VisaWalletRoutable
    ) {
        self.visaWalletModel = visaWalletModel
        self.coordinator = coordinator

        bind()
    }

    func openDeposit() {
        Analytics.log(event: .buttonReceive, params: [.token: visaWalletModel.tokenItem.currencySymbol])

        let addressType = AddressType.default
        let addressInfo = ReceiveAddressInfo(
            address: visaWalletModel.accountAddress,
            type: addressType,
            localizedName: addressType.defaultLocalizedName,
            addressQRImage: QrCodeGenerator.generateQRCode(from: visaWalletModel.accountAddress)
        )
        coordinator.openReceiveScreen(
            amountType: visaWalletModel.tokenItem.amountType,
            blockchain: visaWalletModel.tokenItem.blockchain,
            addressInfos: [addressInfo]
        )
    }

    func openBalancesAndLimits() {
        guard
            let balances = visaWalletModel.balances,
            let limit = visaWalletModel.limits?.currentLimit
        else {
            return
        }

        balancesAndLimitsViewModel = .init(balances: balances, limit: limit)
    }

    func openExplorer() {
        guard let url = visaWalletModel.exploreURL() else {
            return
        }

        coordinator.openExplorer(at: url, blockchainDisplayName: visaWalletModel.tokenItem.blockchain.displayName)
    }

    func exploreTransaction(with id: String) {}

    func reloadTransactionHistory() {}

    func fetchNextTransactionHistoryPage() -> FetchMore? {
        return nil
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        guard updateTask == nil else {
            return
        }

        updateTask = Task { [weak self] in
            await self?.visaWalletModel.generalUpdateAsync()
            completionHandler()
            self?.updateTask = nil
        }
    }

    private func bind() {
        visaWalletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { (self, newState) in
                switch newState {
                case .loading, .notInitialized:
                    break
                case .idle:
                    self.updateLimits()
                case .failedToInitialize(let error):
                    self.failedToLoadInfoNotificationInput = NotificationsFactory().buildNotificationInput(for: error.notificationEvent)
                }
            }
            .store(in: &bag)
    }

    private func updateLimits() {
        guard let limits = visaWalletModel.limits else {
            return
        }

        let balanceFormatter = BalanceFormatter()
        let currentLimit = limits.currentLimit
        let remainingSummary = (currentLimit.remainingOTPAmount ?? 0) + (currentLimit.remainingNoOTPAmount ?? 0)
        cryptoLimitText = balanceFormatter.formatCryptoBalance(remainingSummary, currencyCode: visaWalletModel.tokenItem.currencySymbol)

        let remainingTimeSeconds = Date().distance(to: currentLimit.actualExpirationDate)
        let remainingDays = Int(remainingTimeSeconds / 3600 / 24)
        numberOfDaysLimitText = "available for \(remainingDays) day(s)"
    }
}
