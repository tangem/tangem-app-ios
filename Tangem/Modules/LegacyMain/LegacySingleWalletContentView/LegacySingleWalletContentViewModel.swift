//
//  SingleWalletContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import class UIKit.UIPasteboard
import BlockchainSdk

protocol LegacySingleWalletContentViewModelOutput: OpenCurrencySelectionDelegate {
    func openPushTx(for index: Int, walletModel: WalletModel)
    func openQR(shareAddress: String, address: String, qrNotice: String)
    func openBuyCrypto()
    func showExplorerURL(url: URL?, walletModel: WalletModel)
}

class LegacySingleWalletContentViewModel: ObservableObject {
    @Published var selectedAddressIndex: Int = 0
    @Published var singleWalletModel: WalletModel?

    var balanceViewModel: BalanceViewModel? {
        guard let walletModel = singleWalletModel else { return nil }

        let tokenModel = walletModelsManager.walletModels.first(where: { !$0.isMainToken })
            .map {
                TokenBalanceViewModel(
                    name: $0.name,
                    balance: $0.balance,
                    fiatBalance: $0.fiatBalance
                )
            }

        return BalanceViewModel(
            hasTransactionInProgress: walletModel.hasPendingTx,
            state: walletModel.state,
            name: walletModel.name,
            fiatBalance: walletModel.fiatBalance,
            balance: walletModel.balance,
            tokenBalanceViewModel: tokenModel
        )
    }

    var pendingTransactionViews: [LegacyPendingTxView] {
        guard let singleWalletModel else { return [] }

        let incTxViews = singleWalletModel.incomingPendingTransactions
            .map { LegacyPendingTxView(pendingTx: $0) }

        let outgTxViews = singleWalletModel.outgoingPendingTransactions
            .enumerated()
            .map { index, pendingTx -> LegacyPendingTxView in
                LegacyPendingTxView(pendingTx: pendingTx) { [weak self] in
                    if let singleWalletModel = self?.singleWalletModel {
                        self?.output.openPushTx(for: index, walletModel: singleWalletModel)
                    }
                }
            }

        return incTxViews + outgTxViews
    }

    public var canSend: Bool {
        return singleWalletModel?.wallet.canSend(amountType: .coin) ?? false
    }

    private let totalSumBalanceViewModel: TotalSumBalanceViewModel
    private let walletModelsManager: WalletModelsManager
    private unowned let output: LegacySingleWalletContentViewModelOutput
    private var bag = Set<AnyCancellable>()

    init(
        walletModelsManager: WalletModelsManager,
        totalBalanceProvider: TotalBalanceProviding,
        output: LegacySingleWalletContentViewModelOutput
    ) {
        self.walletModelsManager = walletModelsManager
        self.output = output

        totalSumBalanceViewModel = .init(
            totalBalanceProvider: totalBalanceProvider,
            walletModelsManager: walletModelsManager,
            tapOnCurrencySymbol: output
        )

        /// Initial set to `singleWalletModel`
        singleWalletModel = walletModelsManager.walletModels.first

        bind()
    }

    func onRefresh(done: @escaping () -> Void) {
        walletModelsManager.updateAll(silent: false, completion: done)
    }

    func openQR() {
        guard let walletModel = singleWalletModel else { return }

        let shareAddress = walletModel.shareAddressString(for: selectedAddressIndex)
        let address = walletModel.displayAddress(for: selectedAddressIndex)
        let qrNotice = walletModel.qrReceiveMessage

        output.openQR(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
        Analytics.log(.tokenButtonShowTheWalletAddress)
    }

    func showExplorerURL(url: URL?) {
        guard let walletModel = singleWalletModel else { return }

        output.showExplorerURL(url: url, walletModel: walletModel)
    }

    func copyAddress() {
        Analytics.log(.buttonCopyAddress)
        if let walletModel = singleWalletModel {
            UIPasteboard.general.string = walletModel.displayAddress(for: selectedAddressIndex)
        }
    }

    private func bind() {
        /// Subscribe for update `singleWalletModel` for each changes in `WalletModel`
        walletModelsManager.walletModelsPublisher
            .map { walletModels in
                walletModels
                    .map { $0.objectWillChange }
                    .combineLatest()
                    .map { _ in walletModels }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletModels in
                self?.singleWalletModel = walletModels.first
            }
            .store(in: &bag)

        /// Subscription to handle transaction updates, such as new transactions from send screen.
        walletModelsManager.walletModelsPublisher
            .map { walletModels in
                walletModels
                    .map { $0.walletManager.walletPublisher }
                    .combineLatest()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] publish in
                self?.objectWillChange.send()
            })
            .store(in: &bag)

        singleWalletModel?.$state
            .filter { $0.isSuccesfullyLoaded }
            .delay(for: 0.5, scheduler: DispatchQueue.main) // workaround willChange issue
            .sink { [weak self] state in
                guard
                    let self,
                    let singleWalletModel = self.singleWalletModel
                else {
                    return
                }

                Analytics.logTopUpIfNeeded(balance: singleWalletModel.fiatValue)
            }
            .store(in: &bag)
    }
}
