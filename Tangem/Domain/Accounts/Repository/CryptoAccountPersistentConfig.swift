//
//  CryptoAccountPersistentConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// An intermediate DTO for the repository.
struct CryptoAccountPersistentConfig {
    let derivationIndex: Int
    /// Nil, if the account uses a localized name.
    let name: String?
    let iconName: String
    let iconColor: String
}
