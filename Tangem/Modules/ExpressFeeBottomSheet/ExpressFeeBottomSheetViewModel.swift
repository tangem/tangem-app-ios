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

final class ExpressFeeBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var selectedFeeOption: FeeOption

    // MARK: - Dependencies

    private let swappingFeeFormatter: SwappingFeeFormatter
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressFeeBottomSheetRoutable

    private var currencySymbol: String {
        expressInteractor.getSwappingItems().source.symbol
    }

    // Model will be changed on FeeOption in [REDACTED_INFO]
    private var currencyId: String {
        expressInteractor.getSwappingItems().source.blockchain.currencyID
    }

    init(
        swappingFeeFormatter: SwappingFeeFormatter,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressFeeBottomSheetRoutable
    ) {
        self.swappingFeeFormatter = swappingFeeFormatter
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        selectedFeeOption = {
            switch expressInteractor.getSwappingGasPricePolicy() {
            case .normal:
                return .market
            case .priority:
                return .fast
            }
        }()

        setupView()
    }

    private func setupView() {
        guard case .available(let model) = expressInteractor.state.value else {
            return
        }

        // Model will be changed on FeeOption in [REDACTED_INFO]
        feeRowViewModels = model.gasOptions.map { option in
            makeFeeRowViewModel(gasModel: option)
        }
    }

    private func makeFeeRowViewModel(gasModel: EthereumGasDataModel) -> FeeRowViewModel {
        let option: FeeOption = {
            switch gasModel.policy {
            case .normal:
                return .market
            case .priority:
                return .fast
            }
        }()

        let formatedFee = swappingFeeFormatter.format(fee: gasModel.fee, currencySymbol: currencySymbol, currencyId: currencyId)

        return FeeRowViewModel(
            option: option,
            subtitle: formatedFee,
            isSelected: .init(root: self, default: false, get: { root in
                root.selectedFeeOption == option
            }, set: { root, newValue in
                if newValue {
                    switch option {
                    case .market:
                        root.expressInteractor.update(gasPricePolicy: .normal)
                    case .fast:
                        root.expressInteractor.update(gasPricePolicy: .priority)
                    default:
                        break
                    }

                    root.selectedFeeOption = option
                    root.coordinator.closeExpressFeeBottomSheet()
                }
            })
        )
    }
}
