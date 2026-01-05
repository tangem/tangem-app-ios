//
//  FeeSelectorContentViewModelOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeeSelectorContentViewModelOutput: AnyObject {
    func userDidSelect(selectedFee: FeeSelectorFee)
}

protocol FeeSelectorContentViewModelRoutable: AnyObject {
    func dismissFeeSelector()
    func completeFeeSelection()
}

protocol FeeSelectorContentViewModelAnalytics {
    func logFeeStepOpened()
    func logSendFeeSelected(_ feeOption: FeeOption)
}

protocol FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel]
}

protocol FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool { get }
    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> { get }

    func captureCustomFeeFieldsValue()
    func resetCustomFeeFieldsValue()
}
