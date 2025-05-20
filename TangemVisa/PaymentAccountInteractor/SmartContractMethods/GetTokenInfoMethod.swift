//
//  GetTokenInfoMethod.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GetTokenInfoMethod: SmartContractMethod {
    let infoType: InfoType

    var methodId: String {
        SmartContractMethodIdCreator().createIdForMethod(with: infoType.rawValue)
    }

    var data: Data {
        let prefixData = Data(hexString: methodId)
        return prefixData.trailingZeroPadding(toLength: 32)
    }
}

extension GetTokenInfoMethod {
    enum InfoType: String {
        case contractAddress = "paymentToken()"
        case name = "name()"
        case symbol = "symbol()"
        case decimals = "decimals()"
    }
}
