//
//  SafeInnerCall.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// What a Safe executes on its owners' behalf: a plain transfer or a token contract call.
public struct SafeInnerCall: Hashable {
    public let to: String
    public let value: BigUInt
    public let data: Data

    public init(to: String, value: BigUInt, data: Data) {
        self.to = to
        self.value = value
        self.data = data
    }
}

/// The gas an inner call takes and the price the network asks for it right now, before any buffer or margin.
public struct SafeInnerCallEstimate: Hashable {
    public let gasLimit: BigUInt
    public let gasPrice: BigUInt

    public init(gasLimit: BigUInt, gasPrice: BigUInt) {
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
    }
}
