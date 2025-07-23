//
//  HotAuth.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum HotAuth: Equatable {
    case password(_ password: String)
    case biometrics
}
