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
    func didSendApproveTransaction() // Add data
    func didSendSwapTransaction() // Add data

    func hasPending(for network: String) -> Bool
}
