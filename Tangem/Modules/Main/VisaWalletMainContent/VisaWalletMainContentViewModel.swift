//
//  VisaWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

protocol VisaWalletRoutable: AnyObject {
    func openReceiveScreen(amountType: Amount.AmountType, blockchain: Blockchain, addressInfos: [ReceiveAddressInfo])
    func openExplorer(at url: URL, blockchainDisplayName: String)
}

class VisaWalletMainContentViewModel: ObservableObject {
    @Published var balancesAndLimitsViewModel: VisaBalancesLimitsBottomSheetViewModel?

    @Published private(set) var transactionListViewState: TransactionsListView.State = .loading
    @Published private(set) var isTransactoinHistoryReloading: Bool = true
    @Published private(set) var cryptoLimitText: String = "400.00 USDT"
    @Published private(set) var numberOfDaysLimitText: String = "available 7-day limit"

    private let walletModel: WalletModel
    private unowned let coordinator: VisaWalletRoutable

    private var updateSubscription: AnyCancellable?

    init(
        walletModel: WalletModel,
        coordinator: VisaWalletRoutable
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
    }

    func openDeposit() {
        Analytics.log(event: .buttonReceive, params: [.token: walletModel.tokenItem.currencySymbol])

        let infos = walletModel.wallet.addresses.map { address in
            ReceiveAddressInfo(
                address: address.value,
                type: address.type,
                localizedName: address.localizedName,
                addressQRImage: QrCodeGenerator.generateQRCode(from: address.value)
            )
        }
        coordinator.openReceiveScreen(
            amountType: walletModel.amountType,
            blockchain: walletModel.blockchainNetwork.blockchain,
            addressInfos: infos
        )
    }

    func openBalancesAndLimits() {
        balancesAndLimitsViewModel = .init()
    }

    func openExplorer() {
        guard
            let token = walletModel.tokenItem.token,
            let url = walletModel.exploreURL(for: 0, token: token)
        else {
            return
        }

        coordinator.openExplorer(at: url, blockchainDisplayName: walletModel.blockchainNetwork.blockchain.displayName)
    }

    func exploreTransaction(with id: String) {}

    func reloadTransactionHistory() {}

    func fetchNextTransactionHistoryPage() -> FetchMore? {
        return nil
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        guard updateSubscription == nil else {
            return
        }

        updateSubscription = walletModel.generalUpdate(silent: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                completionHandler()
                self?.updateSubscription = nil
            }
    }
}
