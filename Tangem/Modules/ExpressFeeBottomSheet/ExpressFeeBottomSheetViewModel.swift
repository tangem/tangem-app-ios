//
//  ExpressFeeBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class ExpressFeeBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var selectedFeeOption: FeeOption = .market

    // MARK: - Dependencies

    private unowned let coordinator: ExpressFeeBottomSheetRoutable

    init(coordinator: ExpressFeeBottomSheetRoutable) {
        self.coordinator = coordinator
        setupView()
    }

    private func setupView() {
        feeRowViewModels = [FeeOption.market, .fast].map {
            makeFeeRowViewModel(option: $0)
        }
    }

    private func makeFeeRowViewModel(option: FeeOption) -> FeeRowViewModel {
        FeeRowViewModel(
            option: option,
            subtitle: "0.159817 MATIC (0.22 $)",
            isSelected: .init(root: self, default: false, get: { root in
                root.selectedFeeOption == option
            }, set: { root, newValue in
                if newValue {
                    root.selectedFeeOption = option
                    root.coordinator.closeExpressFeeBottomSheet()
                }
            })
        )
    }
}
