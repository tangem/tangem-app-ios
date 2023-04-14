//
//  CommonExplorerURLService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

// [REDACTED_TODO_COMMENT]
struct CommonExplorerURLService {}

// MARK: - ExplorerURLService

extension CommonExplorerURLService: ExplorerURLService {
    func getExplorerURL(for blockchain: SwappingBlockchain, transactionID: String) -> URL? {
        switch blockchain {
        case .ethereum:
            return URL(string: "https://etherscan.io/tx/\(transactionID)")!
        case .bsc:
            return URL(string: "https://bscscan.com/tx/\(transactionID)")!
        case .polygon:
            return URL(string: "https://polygonscan.com/tx/\(transactionID)")!
        case .avalanche:
            return URL(string: "https://snowtrace.io/tx/\(transactionID)")!
        case .fantom:
            return URL(string: "https://ftmscan.com/tx/\(transactionID)")!
        case .arbitrum:
            return URL(string: "https://arbiscan.io/tx/\(transactionID)")!
        case .gnosis:
            return URL(string: "https://blockscout.com/xdai/mainnet/tx/\(transactionID)")!
        case .optimism:
            return URL(string: "https://optimistic.etherscan.io/tx/\(transactionID)")!
        case .klayth, .aurora:
            return nil
        }
    }
}
