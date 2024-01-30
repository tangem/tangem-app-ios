//
//  GetPaymentAccountMethod.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct GetPaymentAccountMethod: SmartContractMethod {
    let cardWalletAddress: String
    private let methodSignature = "getPaymentAccount(address)"

    var prefix: String {
        SmartContractMethodPrefixCreator().createPrefixForMethod(with: methodSignature)
    }

    var data: Data {
        let prefixData = Data(hexString: prefix)
        let ownerData = Data(hexString: cardWalletAddress).leadingZeroPadding(toLength: 32)
        return prefixData + ownerData
    }
}
