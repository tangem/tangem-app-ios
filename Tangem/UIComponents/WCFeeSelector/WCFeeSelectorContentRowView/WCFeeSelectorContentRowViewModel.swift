//
//  WCFeeSelectorContentRowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

class WCFeeSelectorContentRowViewModel: ObservableObject, Identifiable {
    var id: String { feeOption.title }

    let feeOption: FeeOption
    let feeComponents: FormattedFeeComponents
    let customFields: [FeeSelectorCustomFeeRowViewModel]

    init(
        feeOption: FeeOption,
        feeComponents: FormattedFeeComponents,
        customFields: [FeeSelectorCustomFeeRowViewModel] = []
    ) {
        self.feeOption = feeOption
        self.feeComponents = feeComponents
        self.customFields = customFields
    }
}
