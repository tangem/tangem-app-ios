//
//  ExpressFeeBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping
import struct BlockchainSdk.Fee

final class ExpressFeeBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var selectedFeeOption: FeeOption

    // MARK: - Dependencies

    private let swappingFeeFormatter: SwappingFeeFormatter
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressFeeBottomSheetRoutable

    init(
        swappingFeeFormatter: SwappingFeeFormatter,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressFeeBottomSheetRoutable
    ) {
        self.swappingFeeFormatter = swappingFeeFormatter
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        selectedFeeOption = expressInteractor.getFeeOption()
        setupView()
    }

    private func setupView() {
        let fees = expressInteractor.getState().fees

        // Should use the option's array for the correct order
        feeRowViewModels = [FeeOption.market, .fast].compactMap { option in
            guard let fee = fees[option] else {
                return nil
            }

            return makeFeeRowViewModel(option: option, fee: fee)
        }
    }

    private func makeFeeRowViewModel(option: FeeOption, fee: Fee) -> FeeRowViewModel {
        let tokenItem = expressInteractor.getSender().tokenItem
        let formatedFee = swappingFeeFormatter.format(fee: fee.amount.value, tokenItem: tokenItem)

        return FeeRowViewModel(
            option: option,
            subtitle: formatedFee,
            isSelected: .init(root: self, default: false, get: { root in
                root.selectedFeeOption == option
            }, set: { root, newValue in
                if newValue {
                    root.expressInteractor.updateFeeOption(option: option)
                    root.selectedFeeOption = option
                    root.coordinator.closeExpressFeeBottomSheet()
                }
            })
        )
    }
}
