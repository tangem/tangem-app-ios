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

protocol SingleWalletContentViewModelOutput: OpenCurrencySelectionDelegate {
    func openPushTx(for index: Int, walletModel: WalletModel)
    func openQR(shareAddress: String, address: String, qrNotice: String)
    func showExplorerURL(url: URL?, walletModel: WalletModel)
}

class SingleWalletContentViewModel: ObservableObject {
    @Published var selectedAddressIndex: Int = 0
    @Published var singleWalletModel: WalletModel?

    var pendingTransactionViews: [PendingTxView] {
        guard let singleWalletModel else { return [] }

        let incTxViews = singleWalletModel.incomingPendingTransactions
            .map { PendingTxView(pendingTx: $0) }

        let outgTxViews = singleWalletModel.outgoingPendingTransactions
            .enumerated()
            .map { index, pendingTx -> PendingTxView in
                PendingTxView(pendingTx: pendingTx) { [weak self] in
                    if let singleWalletModel = self?.singleWalletModel {
                        self?.output.openPushTx(for: index, walletModel: singleWalletModel)
                    }
                }
            }

        return incTxViews + outgTxViews
    }

    var canShowAddress: Bool {
        cardModel.canShowAddress
    }

    public var canSend: Bool {
        guard cardModel.canSend else {
            return false
        }

        return singleWalletModel?.wallet.canSend(amountType: .coin) ?? false
    }

    lazy var totalSumBalanceViewModel = TotalSumBalanceViewModel(
        userWalletModel: userWalletModel,
        totalBalanceManager: TotalBalanceProvider(userWalletModel: userWalletModel,
                                                  userWalletAmountType: cardModel.cardAmountType,
                                                  totalBalanceAnalyticsService: TotalBalanceAnalyticsService(totalBalanceCardSupportInfo: totalBalanceCardSupportInfo)),
        cardAmountType: cardModel.cardAmountType,
        tapOnCurrencySymbol: output
    )

    private let cardModel: CardViewModel
    private let userWalletModel: UserWalletModel
    private unowned let output: SingleWalletContentViewModelOutput
    private var bag = Set<AnyCancellable>()
    private var totalBalanceCardSupportInfo: TotalBalanceCardSupportInfo {
        TotalBalanceCardSupportInfo(cardBatchId: cardModel.batchId, cardNumber: cardModel.cardId)
    }

    init(
        cardModel: CardViewModel,
        userWalletModel: UserWalletModel,
        output: SingleWalletContentViewModelOutput
    ) {
        self.cardModel = cardModel
        self.userWalletModel = userWalletModel
        self.output = output

        /// Initial set to `singleWalletModel`
        singleWalletModel = userWalletModel.getWalletModels().first

        bind()
    }

    func onRefresh(done: @escaping () -> Void) {
        userWalletModel.updateAndReloadWalletModels(completion: done)
    }

    func onAppear() {
        userWalletModel.updateAndReloadWalletModels()
        singleWalletModel = userWalletModel.getWalletModels().first
    }

    func openQR() {
        guard let walletModel = singleWalletModel else { return }

        let shareAddress = walletModel.shareAddressString(for: selectedAddressIndex)
        let address = walletModel.displayAddress(for: selectedAddressIndex)
        let qrNotice = walletModel.getQRReceiveMessage()

        output.openQR(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
        Analytics.log(.buttonShowTheWalletAddress)
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
        userWalletModel.subscribeToWalletModels()
            .map { walletModels in
                walletModels
                    .map { $0.objectWillChange }
                    .combineLatest()
                    .map { _ in walletModels }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] walletModels in
                singleWalletModel = walletModels.first
            }
            .store(in: &bag)

        /// Subscription to handle transaction updates, such as new transactions from send screen.
        userWalletModel.subscribeToWalletModels()
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
    }
}
