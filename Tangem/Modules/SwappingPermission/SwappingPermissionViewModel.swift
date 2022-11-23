//
//  SwappingPermissionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SwappingPermissionViewModel: ObservableObject, Identifiable {
    let id: UUID = UUID()
    
    // MARK: - ViewState

    @Published var contentRowViewModels: [DefaultRowViewModel] = []

    let smartContractNetworkName: String

    // MARK: - Dependencies

    private let amount: Decimal
    private let yourWalletAddress: String
    private let spenderWalletAddress: String
    private let fee: Decimal

    // Optional will be removed after integration
    private unowned let coordinator: SwappingPermissionRoutable?

    init(
        smartContractNetworkName: String,
        amount: Decimal,
        yourWalletAddress: String,
        spenderWalletAddress: String,
        fee: Decimal,
        coordinator: SwappingPermissionRoutable?
    ) {
        self.smartContractNetworkName = smartContractNetworkName
        self.amount = amount
        self.yourWalletAddress = yourWalletAddress
        self.spenderWalletAddress = spenderWalletAddress
        self.fee = fee
        self.coordinator = coordinator

        setupView()
    }

    func approveDidTapped() {

    }

    func cancelDidTapped() {

    }
}

private extension SwappingPermissionViewModel {
    func setupView() {
        contentRowViewModels = [
            DefaultRowViewModel(title: "swapping_permission_rows_amount".localized(smartContractNetworkName),
                                detailsType: .text(amount.groupedFormatted())),
            DefaultRowViewModel(title: "swapping_permission_rows_your_wallet".localized,
                                detailsType: .text(yourWalletAddress)),
            DefaultRowViewModel(title: "swapping_permission_rows_spender".localized,
                                detailsType: .text(spenderWalletAddress)),
            DefaultRowViewModel(title: "swapping_permission_rows_fee".localized,
                                detailsType: .text(fee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode))),
        ]
    }
}
