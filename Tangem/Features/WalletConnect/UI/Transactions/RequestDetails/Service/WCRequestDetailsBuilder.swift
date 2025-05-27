//
//  WCRequestDetailsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCRequestDetailsBuilder: Equatable {
    private let method: WalletConnectMethod
    private let source: Data

    init(method: WalletConnectMethod, source: Data) {
        self.method = method
        self.source = source
    }

    func makeRequestDetails() -> [WCTransactionDetailsSection] {
        switch method {
        case .personalSign:
            return WCEthPersonalSignDetailsModel(for: method, source: source).data
        default: return []
        }
    }
}
