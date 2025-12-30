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
    var hasNFCInteraction: Bool { get }
    var latestSignerType: TangemSignerType? { get }
}
