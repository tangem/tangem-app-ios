//
//  ExpressTokensListAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol ExpressTokensListAdapter {
    func walletModels() -> AnyPublisher<[WalletModel], Never>
}
