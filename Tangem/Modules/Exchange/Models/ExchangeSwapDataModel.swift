//
//  ExchangeSwapDataModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ExchangeSwapDataModel {
    let gas: Int
    let gasPrice: String
    let destinationAddress: String
    let sourceAddress: String
    let txData: Data
    let fromTokenAmount: String
    let toTokenAmount: String
    let fromTokenAddress: String?
    let toTokenAddress: String?
}
