//
//  FeeSelectorContentViewModelMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol FeeSelectorContentViewModelMapper {
    func mapToFeeSelectorContentRowViewModels(values: [FeeSelectorFee]) -> [FeeSelectorContentRowViewModel]
}

struct CommonFeeSelectorContentViewModelMapper {
    private let feeFormatter: FeeFormatter
    private let customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder?

    init(feeFormatter: FeeFormatter, customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder?) {
        self.feeFormatter = feeFormatter
        self.customFieldsBuilder = customFieldsBuilder
    }
}

// MARK: - FeeSelectorContentViewModelMapper

extension CommonFeeSelectorContentViewModelMapper: FeeSelectorContentViewModelMapper {
    func mapToFeeSelectorContentRowViewModels(values: [FeeSelectorFee]) -> [FeeSelectorContentRowViewModel] {
        values
            .sorted(by: \.option)
            .map { mapToFeeSelectorContentRowViewModel(fee: $0) }
    }
}

// MARK: - Private

private extension CommonFeeSelectorContentViewModelMapper {
    func mapToFeeSelectorContentRowViewModel(fee: FeeSelectorFee) -> FeeSelectorContentRowViewModel {
        let feeComponents = switch fee.value {
        // [REDACTED_TODO_COMMENT]
        case .loading, .failure:
            FormattedFeeComponents(cryptoFee: "-", fiatFee: .none)

        case .success(let feeValue): feeFormatter.formattedFeeComponents(
                fee: feeValue.amount.value,
                tokenItem: fee.tokenItem,
                formattingOptions: .sendCryptoFeeFormattingOptions
            )
        }

        // We will create the custom fields only for the `.custom` option
        let customFields = fee.option == .custom ? customFields() : []

        return FeeSelectorContentRowViewModel(
            fee: fee,
            feeComponents: feeComponents,
            customFields: customFields
        )
    }

    func customFields() -> [FeeSelectorCustomFeeRowViewModel] {
        customFieldsBuilder?.buildCustomFeeFields() ?? []
    }
}
