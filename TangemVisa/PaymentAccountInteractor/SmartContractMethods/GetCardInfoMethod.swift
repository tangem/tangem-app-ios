//
//  GetCardInfoMethod.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GetCardInfoMethod: SmartContractMethod {
    let cardAddress: String
    private let methodSignature = "cards(address)"

    var prefix: String { SmartContractMethodPrefixCreator().createPrefixForMethod(with: methodSignature) }

    var data: Data {
        let prefixData = Data(hexString: prefix)
        let ownerData = Data(hexString: cardAddress).leadingZeroPadding(toLength: 32)
        return prefixData + ownerData
    }
}

struct GetCardsListMethod: SmartContractMethod {
    private let methodSignature = "activeCardAddresses()"

    var prefix: String { SmartContractMethodPrefixCreator().createPrefixForMethod(with: methodSignature) }

    var data: Data {
        let prefixData = Data(hexString: prefix)
        return prefixData
    }
}
