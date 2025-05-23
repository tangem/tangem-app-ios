//
//  GetTotalBalanceMethod.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GetTotalBalanceMethod: SmartContractMethod {
    let paymentAccountAddress: String
    private let methodSignature = "balanceOf(address)"

    var methodId: String { SmartContractMethodIdCreator().createIdForMethod(with: methodSignature) }

    var data: Data {
        let prefixData = Data(hexString: methodId)
        let ownerData = Data(hexString: paymentAccountAddress).leadingZeroPadding(toLength: 32)
        return prefixData + ownerData
    }
}
