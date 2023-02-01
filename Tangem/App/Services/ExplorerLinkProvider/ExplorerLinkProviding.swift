//
//  ExplorerLinkProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExplorerLinkProviding {
    func getExplorerLink(for blockchain: ExchangeBlockchain, transaction: String) -> URL?
}
