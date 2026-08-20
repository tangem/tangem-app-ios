//
//  PolymarketDepositWalletError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketDepositWalletError: Error, Equatable {
    case invalidOwnerAddress
    case invalidContractConstant
}
