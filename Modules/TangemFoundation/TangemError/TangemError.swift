//
//  TangemError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol TangemError: LocalizedError {
    var errorCode: Int { get }
}
