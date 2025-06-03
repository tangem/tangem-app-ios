//
//  SendFeeSelectorCustomFeeFieldsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct SendFeeSelectorCustomFeeFieldsBuilder: FeeSelectorCustomFeeFieldsBuilder {
    let customFeeService: CustomFeeService?

    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel] {
        guard let customFeeService else {
            return []
        }

        let fields = customFeeService.inputFieldModels().map { field in
            let customFeeField = FeeSelectorCustomFeeRowViewModel(
                title: field.title,
                suffix: field.fieldSuffix,
                isEditable: !field.disabled,
                textFieldViewModel: field.decimalNumberTextFieldViewModel,
                alternativeAmount: nil
            )

            customFeeField.bind(amountAlternativePublisher: field.$amountAlternative.eraseToAnyPublisher())
            return customFeeField
        }

        return fields
    }
}
