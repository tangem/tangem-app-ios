//
//  WCEthSignTypedDataDetailsModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Main model using the parser service
struct WCEthSignTypedDataDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(from method: WalletConnectMethod, source: Data) {
        guard let typedData = try? JSONDecoder().decode(EIP712TypedData.self, from: source) else {
            data = []
            return
        }

        data = WCRequestDetailsEIP712Parser.parse(typedData: typedData, method: method)
    }
}
