//
//  MockExplorerURLService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange

struct MockExplorerURLService: ExplorerURLService {
    func getExplorerURL(for blockchain: ExchangeBlockchain, transactionID: String) -> URL? {
        nil
    }
}
