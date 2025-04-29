//
//  UTXOLockingScript.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct UTXOLockingScript: Hashable {
    /// `Locking Script Data` Will be use in output
    public let data: Data

    /// The type which impact on `redeemScript` and `lockingScript`
    public let type: UTXOScriptType

    /// The required field to make spending input
    /// Will be `nil` if we can not spend output
    public let spendable: SpendableType?
}

public extension UTXOLockingScript {
    /// The value which allow us to spend the utxo
    enum SpendableType: Hashable {
        case publicKey(Data)
        case redeemScript(Data)
    }
}
