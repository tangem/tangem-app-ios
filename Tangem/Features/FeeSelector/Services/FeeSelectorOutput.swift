//
//  FeeSelectorOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol FeeSelectorOutput: AnyObject {
    func userDidSelect(selectedFee: TokenFee)
}

protocol FeeSelectorRoutable: AnyObject {
    func dismissFeeSelector()
    func completeFeeSelection()
}

protocol FeeSelectorAnalytics {
    func logFeeStepOpened()
    func logSendFeeSelected(_ feeOption: FeeOption)
}

// MARK: - Custom fee

protocol FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel]
}

protocol FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool { get }
    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> { get }

    func captureCustomFeeFieldsValue()
    func resetCustomFeeFieldsValue()
}
