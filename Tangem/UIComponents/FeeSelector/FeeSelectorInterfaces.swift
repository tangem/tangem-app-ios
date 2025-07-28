//
//  FeeSelectorInterfaces.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemUI

struct FeeSelectorFee {
    let option: FeeOption
    let value: Decimal
}

protocol FeeSelectorContentViewModelInput: AnyObject {
    var selectedSelectorFee: FeeSelectorFee? { get }
    var selectedSelectorFeePublisher: AnyPublisher<FeeSelectorFee, Never> { get }

    var selectorFees: [FeeSelectorFee] { get }
    var selectorFeesPublisher: AnyPublisher<LoadingResult<[FeeSelectorFee], Never>, Never> { get }
}

protocol FeeSelectorContentViewModelOutput: AnyObject {
    func update(selectedSelectorFee: FeeSelectorFee)
    func dismissFeeSelector()
    func completeFeeSelection()
}

protocol FeeSelectorContentViewModelAnalytics {
    func logSendFeeSelected(_ feeOption: FeeOption)
}

protocol FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel]
}
