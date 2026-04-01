//
//  AccountsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// A top-level namespace.
enum AccountsDTO {}

/// Shared DTO types used by both request and response models.
extension AccountsDTO {
    enum GroupType: String, Codable {
        case none
        case network
    }

    enum SortType: String, Codable {
        case manual
        case balance
    }
}

/// A second-level namespace.
extension AccountsDTO {
    enum Request {}
}

/// A second-level namespace.
extension AccountsDTO {
    enum Response {}
}
