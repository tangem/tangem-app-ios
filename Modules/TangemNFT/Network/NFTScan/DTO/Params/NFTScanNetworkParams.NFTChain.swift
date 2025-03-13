//
//  NFTScanNetworkResult.NFTChain.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension NFTScanNetworkParams {
    enum NFTChain: String {
        case solana

        var apiBasePath: URL {
            switch self {
            case .solana:
                URL(string: "https://solanaapi.nftscan.com/api/sol/")!
            }
        }
    }
}
