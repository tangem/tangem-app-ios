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
    private unowned let coordinator: SwappingPermissionRoutable

    init(
        inputModel: InputModel,
        coordinator: SwappingPermissionRoutable
    ) {
        self.smartContractNetworkName = inputModel.smartContractNetworkName
        self.amount = inputModel.amount
        self.yourWalletAddress = inputModel.yourWalletAddress
        self.spenderWalletAddress = inputModel.spenderWalletAddress
        self.fee = inputModel.fee
        self.coordinator = coordinator

        setupView()
    }

    func approveDidTapped() {
        coordinator.userDidApprove()
    }

    func cancelDidTapped() {
        coordinator.userDidCancel()
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

extension SwappingPermissionViewModel {
    struct InputModel {
        let smartContractNetworkName: String
        let amount: Decimal
        let yourWalletAddress: String
        let spenderWalletAddress: String
        let fee: Decimal
    }
}
