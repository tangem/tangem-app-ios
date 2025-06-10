//
//  UTXONetworkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UTXONetworkProvider: UTXONetworkAddressInfoProvider {
    func getFee() -> AnyPublisher<UTXOFee, Error>
    func send(transaction: String) -> AnyPublisher<TransactionSendResult, Error>
}
