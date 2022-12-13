//
//  SwappingPermissionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExchange

final class SwappingPermissionViewModel: ObservableObject, Identifiable {
    /// For SwiftUI sheet logic
    let id: UUID = UUID()

    // MARK: - ViewState

    @Published var contentRowViewModels: [DefaultRowViewModel] = []

    var tokenSymbol: String {
        transactionInfo.currency.symbol
    }

    // MARK: - Dependencies

    private let transactionInfo: ExchangeTransactionInfo
    private let transactionSender: TransactionSenderProtocol
    private unowned let coordinator: SwappingPermissionRoutable

    init(
        transactionInfo: ExchangeTransactionInfo,
        transactionSender: TransactionSenderProtocol,
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
                try await transactionSender.sendPermissionTransaction(transactionInfo, gasPrice: transactionInfo.fee)
                DispatchQueue.main.async {
                    self.coordinator.userDidApprove()
                }
            } catch {
                assertionFailure(error.localizedDescription)
                // [REDACTED_TODO_COMMENT]
            }
        }
    }

    func didTapCancel() {
        coordinator.userDidCancel()
    }
}

private extension SwappingPermissionViewModel {
    func setupView() {
        let walletAddress = transactionInfo.source.prefix(8) + "..." + transactionInfo.source.suffix(8)
        let spenderAddress = transactionInfo.destination.prefix(8) + "..." + transactionInfo.destination.suffix(8)

        let fee = transactionInfo.fee.groupedFormatted(maximumFractionDigits: transactionInfo.currency.decimalCount)
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
