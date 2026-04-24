//
//  CardanoFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

struct CardanoFeeParameters: FeeParameters {
    let adaValue: UInt64
    let change: UInt64
    let useMaxAmount: Bool
}
