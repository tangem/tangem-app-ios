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

        return customFeeService.selectorCustomFeeRowViewModels()
    }
}
