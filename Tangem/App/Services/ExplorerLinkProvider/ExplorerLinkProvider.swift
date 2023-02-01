//
//  ExplorerLinkProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

// [REDACTED_TODO_COMMENT]
struct ExplorerLinkProvider {}

// MARK: - ExplorerLinkProviding

extension ExplorerLinkProvider: ExplorerLinkProviding {
    func getExplorerLink(for blockchain: ExchangeBlockchain, transaction: String) -> URL? {
        switch blockchain {
        case .ethereum:
            return URL(string: "https://etherscan.io/tx/\(transaction)")!
        case .bsc:
            return URL(string: "https://bscscan.com/tx/\(transaction)")!
        case .polygon:
            return URL(string: "https://polygonscan.com/tx/\(transaction)")!
        case .avalanche:
            return URL(string: "https://snowtrace.io/tx/\(transaction)")!
        case .fantom:
            return URL(string: "https://ftmscan.com/tx/\(transaction)")!
        case .arbitrum:
            return URL(string: "https://arbiscan.io/tx/\(transaction)")!
        case .gnosis:
            return URL(string: "https://blockscout.com/xdai/mainnet/tx/\(transaction)")!
        case .optimism:
            return URL(string: "https://optimistic.etherscan.io/tx/\(transaction)")!
        case .klayth, .aurora:
            return nil
        }
    }
}
