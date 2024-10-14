//
//  TronFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public struct TronFeeParameters: FeeParameters {
    public let energySpent: Int
    public let energyFullyCoversFee: Bool
}
