//
//  FeeSelectorFeesViewModelMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol FeeSelectorFeesViewModelMapper {
    func mapToFeeSelectorFeesRowViewModels(values: [TokenFee]) -> [FeeSelectorFeesRowViewModel]
}

struct CommonFeeSelectorFeesViewModelMapper {
    private let feeFormatter: FeeFormatter
    private let customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder?

    init(feeFormatter: FeeFormatter, customFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder? = nil) {
        self.feeFormatter = feeFormatter
        self.customFieldsBuilder = customFieldsBuilder
    }
}

// MARK: - FeeSelectorFeesViewModelMapper

extension CommonFeeSelectorFeesViewModelMapper: FeeSelectorFeesViewModelMapper {
    func mapToFeeSelectorFeesRowViewModels(values: [TokenFee]) -> [FeeSelectorFeesRowViewModel] {
        values
            .sorted(by: \.option)
            .map { mapToFeeSelectorFeesRowViewModel(fee: $0) }
    }
}

// MARK: - Private

private extension CommonFeeSelectorFeesViewModelMapper {
    func mapToFeeSelectorFeesRowViewModel(fee: TokenFee) -> FeeSelectorFeesRowViewModel {
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

        return FeeSelectorFeesRowViewModel(
            fee: fee,
            feeComponents: feeComponents,
            customFields: customFields
        )
    }

    func customFields() -> [FeeSelectorCustomFeeRowViewModel] {
        customFieldsBuilder?.buildCustomFeeFields() ?? []
    }
}
