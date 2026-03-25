//
//  SendDestination.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendDestination: Equatable {
    let value: Destination
    let source: Analytics.DestinationAddressSource
}

extension SendDestination {
    enum Destination: Hashable {
        case plain(String)
        case resolved(address: String, resolved: String, memoRequired: Bool)

        /// The address which user typed in the text field
        var typedAddress: String {
            switch self {
            case .plain(let address): address
            case .resolved(let address, _, _): address
            }
        }

        /// The address which have to be used as transaction destination
        var transactionAddress: String {
            switch self {
            case .plain(let address): address
            case .resolved(_, let resolved, _): resolved
            }
        }

        /// Resolved address. Will be nil if equal to usual address
        var showableResolved: String? {
            switch self {
            case .plain: nil
            case .resolved(let address, let resolved, _): address == resolved ? nil : resolved
            }
        }

        var isResolved: Bool {
            switch self {
            case .plain: return false
            case .resolved(let address, let resolved, _): return address == resolved ? false : true
            }
        }
    }
}
