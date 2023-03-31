//
//  ExplorerURLService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping
import Foundation

protocol ExplorerURLService {
    func getExplorerURL(for blockchain: SwappingBlockchain, transactionID: String) -> URL?
}
