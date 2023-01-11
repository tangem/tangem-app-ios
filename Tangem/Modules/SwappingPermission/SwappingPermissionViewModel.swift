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
        inputModel.transactionInfo.sourceCurrency.symbol
    }

    // MARK: - Dependencies

    private let inputModel: SwappingPermissionInputModel
    private let transactionSender: TransactionSendable
    private unowned let coordinator: SwappingPermissionRoutable

    init(
        inputModel: SwappingPermissionInputModel,
        transactionSender: TransactionSendable,
        coordinator: SwappingPermissionRoutable
    ) {
        self.inputModel = inputModel
        self.transactionSender = transactionSender
        self.coordinator = coordinator

        setupView()
    }

    func didTapApprove() {
        Task {
            do {
                try await transactionSender.sendTransaction(inputModel.transactionInfo)
                await didSendApproveTransaction()
            } catch TangemSdkError.userCancelled {
                // Do nothing
            } catch {
                errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
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
        let transactionInfo = inputModel.transactionInfo
        /// Addresses have to the same width for both
        let walletAddress = AddressFormatter(address: transactionInfo.sourceAddress).truncated()
        let spenderAddress = AddressFormatter(address: transactionInfo.destinationAddress).truncated()

        let fee = transactionInfo.fee.rounded(scale: 2, roundingMode: .up)
        let fiatFee = inputModel.fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        let formattedFee = "\(fee.groupedFormatted()) \(inputModel.transactionInfo.sourceBlockchain.symbol) (\(fiatFee))"

        contentRowViewModels = [
            DefaultRowViewModel(title: Localization.swappingPermissionRowsAmount(tokenSymbol),
                                detailsType: .icon(Assets.infinityMini)),
            DefaultRowViewModel(title: Localization.swappingPermissionRowsYourWallet,
                                detailsType: .text(String(walletAddress))),
            DefaultRowViewModel(title: Localization.swappingPermissionRowsSpender,
                                detailsType: .text(String(spenderAddress))),
            DefaultRowViewModel(title: Localization.sendFeeLabel,
                                detailsType: .text(formattedFee)),
        ]
    }
}
