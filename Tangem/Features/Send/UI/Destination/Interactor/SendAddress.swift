//
//  SendAddress.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendAddress: Equatable {
    let value: Destination
    let source: Analytics.DestinationAddressSource
}

extension SendAddress {
    enum Destination: Hashable {
        case plain(String)
        case resolved(address: String, resolved: String)

        /// The address which user typed in the text field
        var typedAddress: String {
            switch self {
            case .plain(let address): address
            case .resolved(let address, _): address
            }
        }

        /// The address which have to be used as transaction destination
        var transactionAddress: String {
            switch self {
            case .plain(let address): address
            case .resolved(let address, let resolved): resolved
            }
        }

        /// Resolved address. Will be nil if equal to usual address
        var showableResolved: String? {
            switch self {
            case .plain: nil
            case .resolved(let address, let resolved): address == resolved ? nil : resolved
            }
        }
    }
}
