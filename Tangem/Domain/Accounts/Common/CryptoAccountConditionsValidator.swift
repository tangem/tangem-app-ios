//
//  CryptoAccountConditionsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol CryptoAccountConditionsValidator {
    associatedtype ValidationError: Error

    func validate() async throws(ValidationError)
}
