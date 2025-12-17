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
