//
//  NotificationDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum NotificationDTO {
    /// Represents a network item with basic information
    struct NetworkItem: Decodable {
        /// Unique identifier for the network item
        let id: Int
        /// The network identifier (e.g., "arbitrum-one")
        let networkId: String
        /// The display name of the network
        let name: String
        /// Indicates whether tokens are available for this network
        let tokenAvailable: Bool
    }
}
