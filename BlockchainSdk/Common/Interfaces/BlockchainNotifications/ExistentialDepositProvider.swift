//
//  ExistentialDepositProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public protocol ExistentialDepositProvider {
    var existentialDeposit: Amount { get }
}
