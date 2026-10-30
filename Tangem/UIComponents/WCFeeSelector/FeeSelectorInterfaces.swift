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

    var selectorFeesPublisher: AnyPublisher<LoadingResult<[WCFeeSelectorFee], Never>, Never> { get }
}

protocol WCFeeSelectorContentViewModelOutput: AnyObject {
    func update(selectedFeeOption: FeeOption)
    func dismissFeeSelector()
    func completeFeeSelection()
}
