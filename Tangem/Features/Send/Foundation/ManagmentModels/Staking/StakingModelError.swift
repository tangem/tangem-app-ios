//
//  StakingModelError.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum StakingModelError: String, Hashable, LocalizedError {
    case accountIsNotInitialized
    case transactionBlocked

    var errorDescription: String? { rawValue }
}
