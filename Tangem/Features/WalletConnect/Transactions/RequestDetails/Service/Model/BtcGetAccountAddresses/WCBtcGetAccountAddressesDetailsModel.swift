//
//  WCBtcGetAccountAddressesDetailsModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WCBtcGetAccountAddressesDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data) {
        guard let request = try? JSONDecoder().decode(WalletConnectBtcGetAccountAddressesRequest.self, from: source) else {
            data = []
            return
        }

        data = WCRequestDetailsBtcGetAccountAddressesParser.parse(
            request: request,
            method: method
        )
    }
}
