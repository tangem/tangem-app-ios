//
//  Analytics+SignInType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum SignInType: String {
        case biometrics = "Biometric"
        case card = "Card"
        case noSecurity = "No Security"
        case accessCode = "Access Code"
    }
}
