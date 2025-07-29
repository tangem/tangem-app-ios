//
//  Authentication.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

struct Authentication {
    let accessCode: String
    let biometrics: Bool
}

public enum AuthenticationUnlockData {
    case none
    case accessCode(_ accessCode: String)
    case biometrics(context: LAContext)
}
