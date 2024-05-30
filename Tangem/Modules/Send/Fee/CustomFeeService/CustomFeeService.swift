//
//  CustomFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CustomFeeService: AnyObject {
    var customFeeDescription: String? { get }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel]
}

protocol EditableCustomFeeService: CustomFeeService {
    func setCustomFee(value: Decimal?)
}
