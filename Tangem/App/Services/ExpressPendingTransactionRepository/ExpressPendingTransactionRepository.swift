//
//  ExpressPendingTransactionRepository.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

public protocol ExpressPendingTransactionRepository {
    func didSendApproveTransaction(swappingTxData: SwappingTransactionData)
    func didSendSwapTransaction(swappingTxData: SwappingTransactionData)

    func hasPending(for network: String) -> Bool
}
