//
//  FeeSelectorFeesRowData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FeeSelectorFeesRowViewModel: ObservableObject, Identifiable {
    var id: String { fee.option.title }

    let fee: LoadableTokenFee
    let feeComponents: FormattedFeeComponents
    let customFields: [FeeSelectorCustomFeeRowViewModel]

    init(
        fee: LoadableTokenFee,
        feeComponents: FormattedFeeComponents,
        customFields: [FeeSelectorCustomFeeRowViewModel] = []
    ) {
        self.fee = fee
        self.feeComponents = feeComponents
        self.customFields = customFields
    }
}
