//
//  TransactionSender.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionSenderProtocol {
    func sendExchangeTransaction(_ info: ExchangeTransactionDataModel) async throws
    func sendPermissionTransaction(_ info: ExchangeTransactionDataModel) async throws
}
