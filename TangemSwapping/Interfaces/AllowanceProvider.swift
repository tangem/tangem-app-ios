//
//  AllowanceProvider.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol AllowanceProvider {
    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal
    func makeApproveData(spender: String, amount: Decimal) throws -> Data
}
