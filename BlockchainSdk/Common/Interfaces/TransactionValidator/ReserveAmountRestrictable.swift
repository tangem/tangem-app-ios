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
    func validateReserveAmount(amount: Amount, address: String) async throws
}

extension ReserveAmountRestrictable {
    func validateReserveAmount(amount: Amount, destination: DestinationType) async throws {
        switch destination {
        case .generate:
            return
        case .address(let string):
            try await validateReserveAmount(amount: amount, address: string)
        }
    }
}
