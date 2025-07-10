//
//  ABIEncoder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ABIEncoder {
    func encode(method: String, parameters: [SmartContractMethodParameterType]) -> String
}
