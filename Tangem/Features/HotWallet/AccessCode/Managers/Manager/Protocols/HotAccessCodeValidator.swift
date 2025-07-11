//
//  HotAccessCodeValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotAccessCodeValidator {
    func isValid(accessCode: String) -> Bool
}
