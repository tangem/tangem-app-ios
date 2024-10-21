//
//  ExpressTransaction.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressTransaction {
    public let providerId: ExpressProvider.Id
    public let externalStatus: ExpressTransactionStatus
    public let refundedCurrency: ExpressCurrency?
}
