//
//  ExpressDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ExpressDependenciesFactory {
    var userWalletInfo: UserWalletInfo { get }
    var expressManager: ExpressManager { get }
    var swapRepository: SwapRepository { get }
    var expressPendingTransactionRepository: ExpressPendingTransactionRepository { get }
    var expressDestinationService: ExpressDestinationService { get }
    var expressAPIProvider: ExpressAPIProvider { get }

    var onrampRepository: OnrampRepository { get }
}
