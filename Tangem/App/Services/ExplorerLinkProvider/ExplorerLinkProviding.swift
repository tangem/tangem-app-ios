//
//  ExplorerLinkProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange

protocol ExplorerLinkProviding {
    func getExplorerURL(for blockchain: ExchangeBlockchain, transaction: String) -> URL?
}
