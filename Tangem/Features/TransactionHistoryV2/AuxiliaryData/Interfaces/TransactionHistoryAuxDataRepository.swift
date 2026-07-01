//
//  TransactionHistoryAuxDataRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol TransactionHistoryAuxDataRepository: Sendable {
    var didLoadAuxData: AsyncStream<Void> { get }

    // MARK: Providers

    /// - Note: Fires a background load on a cache miss.
    nonisolated func provider(id: ExpressProvider.Id) -> ExpressProvider?

    /// - Note: Fires (and awaiting) a load on a cache miss.
    func provider(id: ExpressProvider.Id) async -> ExpressProvider?

    // MARK: Fiat currencies

    /// - Note: Fires a background load on a cache miss.
    nonisolated func fiatCurrency(for asset: OnrampHistoryFiatAsset) -> OnrampFiatCurrency?

    /// - Note: Fires (and awaiting) a load on a cache miss.
    func fiatCurrency(for asset: OnrampHistoryFiatAsset) async -> OnrampFiatCurrency?

    // MARK: Crypto currencies

    /// - Note: Fires a background load on a cache miss.
    nonisolated func coin(for tokenItem: TokenItem) -> CoinsList.Coin?

    /// - Note: Fires (and awaiting) a load on a cache miss.
    func coin(for tokenItem: TokenItem) async -> CoinsList.Coin?
}
