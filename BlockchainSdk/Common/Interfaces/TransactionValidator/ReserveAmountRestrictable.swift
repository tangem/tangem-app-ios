//
//  ReserveAmountRestrictable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol ReserveAmountRestrictable {
    func validateReserveAmount(amount: Amount, addressType: ReserveAmountRestrictableAddressType) async throws
}

extension ReserveAmountRestrictable {
    func validateReserveAmount(amount: Amount, destination: DestinationType) async throws {
        switch destination {
        case .generate:
            try await validateReserveAmount(amount: amount, addressType: .notCreated)
        case .address(let string):
            try await validateReserveAmount(amount: amount, addressType: .address(string))
        }
    }
}

enum ReserveAmountRestrictableAddressType {
    /// The specified address will be used for verification
    case address(String)
    /// It will be considered as an absolute brand new address for verification
    case notCreated
}
