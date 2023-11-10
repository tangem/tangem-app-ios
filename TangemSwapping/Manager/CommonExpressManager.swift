//
//  CommonExpressManager.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonExpressManager {
    // MARK: - Dependencies

    private let expressAPIProvider: ExpressAPIProvider
    private let logger: SwappingLogger

    // MARK: - State

    /// The amount in cents
    private var _amount: Decimal?
    private var _provider: ExpressProvider?
    private var _fromWallet: ExpressWallet
    private var _toWallet: ExpressWallet?

    // MARK: - Internal

    private var bag: Set<AnyCancellable> = []

    private var formattedAmount: String? {
        guard let amount = _amount else {
            logger.debug("[Swap] Amount isn't set")
            return nil
        }

        return String(describing: _fromWallet.convertToWEI(value: amount))
    }

    private var fromWalletAddress: String {
        _fromWallet.address
    }

    init(
        expressAPIProvider: ExpressAPIProvider,
        logger: SwappingLogger
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.logger = logger
    }
}

// MARK: - SwappingManager

extension CommonExpressManager: ExpressManager {
    var amount: Decimal? {
        get { _amount }
        set { _amount = newValue }
    }

    var fromWallet: ExpressWallet {
        get { _fromWallet }
        set { _fromWallet = newValue }
    }

    var toWallet: ExpressWallet? {
        get { _toWallet }
        set { _toWallet = newValue }
    }

    var provider: ExpressProvider? {
        get { _provider }
        set { _provider = newValue }
    }

    func refresh() async -> SwappingAvailabilityState {
        return await refreshValues()
    }
}

// MARK: - Requests

private extension CommonExpressManager {
    func refreshValues() async -> SwappingAvailabilityState {
        
    }
}
