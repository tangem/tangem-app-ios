//
//  TangemPayBalance.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayBalance: Decodable, Equatable {
    public let fiat: Fiat
    public let crypto: Crypto
    public let availableForWithdrawal: AvailableForWithdrawal
}

public extension TangemPayBalance {
    struct Fiat: Decodable, Equatable {
        public let currency: String
        public let availableBalance: Decimal
        public let creditLimit: Decimal
        public let pendingCharges: Decimal
        public let postedCharges: Decimal
        public let balanceDue: Decimal
    }

    struct Crypto: Decodable, Equatable {
        public let id: String
        public let chainId: Int
        public let depositAddress: String
        public let tokenContractAddress: String
        public let balance: Decimal
    }

    struct AvailableForWithdrawal: Decodable, Equatable {
        public let amount: Decimal
        public let currency: String
    }
}
