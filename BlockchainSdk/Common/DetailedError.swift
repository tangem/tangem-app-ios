//
//  DetailedError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol DetailedError {
    var detailedDescription: String? { get }
}
