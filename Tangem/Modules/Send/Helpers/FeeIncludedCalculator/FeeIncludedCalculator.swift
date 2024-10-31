//
//  FeeIncludedCalculator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol FeeIncludedCalculator {
    func shouldIncludeFee(_ fee: Fee, into amount: Amount) -> Bool
}
