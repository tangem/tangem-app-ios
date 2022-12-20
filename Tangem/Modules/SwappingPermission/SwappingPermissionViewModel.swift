//
//  SwappingPermissionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExchange
import TangemSdk

final class SwappingPermissionViewModel: ObservableObject, Identifiable {
    /// For SwiftUI sheet logic
    let id: UUID = UUID()

    // MARK: - ViewState

    @Published var contentRowViewModels: [DefaultRowViewModel] = []
    @Published var errorAlert: AlertBinder?

    var tokenSymbol: String {
        transactionInfo.sourceCurrency.symbol
    }

    // MARK: - Dependencies

    private let transactionInfo: ExchangeTransactionDataModel
    private let transactionSender: TransactionSendable
    private unowned let coordinator: SwappingPermissionRoutable

    init(
        transactionInfo: ExchangeTransactionDataModel,
        transactionSender: TransactionSendable,
        coordinator: SwappingPermissionRoutable
    ) {
        self.transactionInfo = transactionInfo
        self.transactionSender = transactionSender
        self.coordinator = coordinator

        setupView()
    }

    func didTapApprove() {
        Task {
            do {
                try await transactionSender.sendTransaction(transactionInfo)
                await didSendApproveTransaction()
            } catch TangemSdkError.userCancelled {
                // Do nothing
            } catch {
                errorAlert = AlertBinder(title: "common_error".localized, message: error.localizedDescription)
            }
        }
    }

    func didTapCancel() {
        coordinator.userDidCancel()
    }
}

// MARK: - Navigation

extension SwappingPermissionViewModel {
    @MainActor
    func didSendApproveTransaction() {
        coordinator.didSendApproveTransaction()
    }
}

// MARK: - Private

private extension SwappingPermissionViewModel {
    func setupView() {
        /// Addresses have to the same width for both
        let walletAddress = AddressFormatter(address: transactionInfo.sourceAddress).truncated()
        let spenderAddress = AddressFormatter(address: transactionInfo.destinationAddress).truncated()

        let fee = transactionInfo.fee.groupedFormatted(
            maximumFractionDigits: transactionInfo.sourceCurrency.decimalCount
        )

        contentRowViewModels = [
            DefaultRowViewModel(title: "swapping_permission_rows_amount".localized(tokenSymbol),
                                detailsType: .icon(Assets.infinityMini)),
            DefaultRowViewModel(title: "swapping_permission_rows_your_wallet".localized,
                                detailsType: .text(String(walletAddress))),
            DefaultRowViewModel(title: "swapping_permission_rows_spender".localized,
                                detailsType: .text(String(spenderAddress))),
            DefaultRowViewModel(title: "send_fee_label".localized,
                                detailsType: .text(fee)),
        ]
    }
}
