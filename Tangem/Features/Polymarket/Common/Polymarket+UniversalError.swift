//
//  Polymarket+UniversalError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

// `Subsystems`:
// `000` - PolymarketWithdrawTransactionService.Error
// `001` - PolymarketWithdrawError (the backend's answer to a withdrawal)
// `002` -
// `003` -

extension PolymarketWithdrawTransactionService.Error: UniversalError {
    var errorCode: Int {
        switch self {
        case .withdrawInProgress:
            112000000
        case .destinationAssetUnavailable:
            112000001
        case .bridgeAddressUnavailable:
            112000002
        case .amountNotRepresentable:
            112000003
        case .calldataMismatch:
            112000004
        case .notSigned:
            112000005
        case .preparationFailed:
            112000006
        case .transferFailed:
            112000007
        case .reconnectRequired:
            112000008
        case .refused(let refusal):
            refusal.errorCode
        }
    }
}

private extension PolymarketWithdrawError {
    var errorCode: Int {
        switch self {
        case .badRequest:
            112001000
        case .unauthorized:
            112001001
        case .foreignDepositWallet:
            112001002
        case .notFound:
            112001003
        case .conflict:
            112001004
        case .relayerRejected:
            112001005
        case .upstreamUnavailable:
            112001006
        case .cancelled:
            112001007
        case .other:
            112001008
        }
    }
}
