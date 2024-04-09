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
    var readOnlyCustomFee: Bool { get }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel]
    func setCustomFee(value: Decimal?)
}
