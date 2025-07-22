//
//  HotAuth.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

public struct Authentication {
    let passcode: String?
    let biometrics: Bool
}

public enum AuthenticationUnlockData {
    case passcode(_ passcode: String)
    case biometrics(context: LAContext)
}
    
