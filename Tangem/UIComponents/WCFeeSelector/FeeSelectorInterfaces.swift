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

enum FeeSelectorDismissButtonType {
    case back
    case close
}

enum FeeSelectorSavingType {
    case autosave
    case doneButton
}

struct WCFeeSelectorFee {
    let option: FeeOption
    let value: Decimal
}

protocol WCFeeSelectorContentViewModelInput: AnyObject {
    var selectedSelectorFee: WCFeeSelectorFee? { get }
    var selectedSelectorFeePublisher: AnyPublisher<WCFeeSelectorFee, Never> { get }

    var selectorFees: [WCFeeSelectorFee] { get }
    var selectorFeesPublisher: AnyPublisher<LoadingResult<[WCFeeSelectorFee], Never>, Never> { get }
}

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
    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> { get }

    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel]
    func captureCustomFeeFieldsValue()
    func resetCustomFeeFieldsValue()
}

protocol FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool { get }
    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> { get }

    func captureCustomFeeFieldsValue()
    func resetCustomFeeFieldsValue()
}

// MAKR: Legacy

protocol WCFeeSelectorContentViewModelOutput: AnyObject {
    func update(selectedFeeOption: FeeOption)
    func dismissFeeSelector()
    func completeFeeSelection()
}
