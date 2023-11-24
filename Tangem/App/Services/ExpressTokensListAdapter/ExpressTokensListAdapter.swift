//
//  ExpressTokensListAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressTokensListAdapter {
    func walletModels() async -> AsyncStream<[WalletModel]>
}
