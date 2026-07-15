//
//  WCBtcSignPsbtDetailsModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WCBtcSignPsbtDetailsModel {
    let data: [WCTransactionDetailsSection]

    init(for method: WalletConnectMethod, source: Data) {
        guard let request = try? JSONDecoder().decode(WalletConnectBitcoinSignPsbtDTO.Request.self, from: source) else {
            data = []
            return
        }

        data = WCRequestDetailsBtcSignPsbtParser.parse(
            request: request,
            method: method
        )
    }
}
