//
//  ExchangeManagerError.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ExchangeManagerError: Error {
    case walletAddressNotFound
    case destinationNotFound
    case amountNotFound
    case permitCannotCreated
}
