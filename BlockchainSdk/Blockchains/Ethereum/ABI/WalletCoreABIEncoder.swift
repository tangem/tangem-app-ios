//
//  WalletCoreABIEncoder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

struct WalletCoreABIEncoder: ABIEncoder {
    func encode(method: String, parameters: [SmartContractMethodParameterType]) -> String {
        let function = EthereumAbiFunction(name: method)
        for parameter in parameters {
            switch parameter {
            case .bytes(let data):
                function.addParamBytes(val: data, isOutput: false)
            }
        }

        let encodedData = EthereumAbi.encode(fn: function)

        return encodedData.hexString.addHexPrefix()
    }
}
