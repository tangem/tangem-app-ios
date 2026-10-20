//
//  AccountConditionsValidatorFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AccountConditionsValidatorFactory {
    func makeValidator(for flow: AccountValidationFlow) -> any CryptoAccountConditionsValidator
}
