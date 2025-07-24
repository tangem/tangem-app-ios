//
//  TangemSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//
import Foundation
import BlockchainSdk

protocol TangemSigner: TransactionSigner {
    var latestSignerType: TangemSignerType? { get }
}
