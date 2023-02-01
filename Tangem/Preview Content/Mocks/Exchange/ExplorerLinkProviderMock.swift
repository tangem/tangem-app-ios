//
//  CommonExplorerURLServiceMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange

struct CommonExplorerURLServiceMock: ExplorerURLService {
    func getExplorerURL(for blockchain: ExchangeBlockchain, transaction: String) -> URL? {
        nil
    }
}
