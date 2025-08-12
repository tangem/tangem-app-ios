//
//  Authentication.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

public enum AuthenticationUnlockData: Hashable {
    case none
    case accessCode(_ accessCode: String)
    case biometrics(context: LAContext)
}
