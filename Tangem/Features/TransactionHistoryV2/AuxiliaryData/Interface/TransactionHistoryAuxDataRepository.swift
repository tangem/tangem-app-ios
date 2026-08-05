//
//  TransactionHistoryAuxDataRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

protocol TransactionHistoryAuxDataRepository: Sendable {
    var didLoadAuxData: AsyncStream<Void> { get }

    // MARK: Providers

    /// - Note: Fires a background load on a cache miss.
    nonisolated func provider(id: ExpressProvider.Id, branch: ExpressBranch) -> ExpressProvider?

    /// - Note: Fires (and awaits) a load on a cache miss.
    func provider(id: ExpressProvider.Id, branch: ExpressBranch) async -> ExpressProvider?

    // MARK: Fiat currencies

    /// - Note: Fires a background load on a cache miss.
    nonisolated func fiatCurrency(for asset: OnrampHistoryFiatAsset) -> OnrampFiatCurrency?

    /// - Note: Fires (and awaits) a load on a cache miss.
    func fiatCurrency(for asset: OnrampHistoryFiatAsset) async -> OnrampFiatCurrency?

    // MARK: Crypto currencies

    /// - Note: Fires a background load on a cache miss.
    /// - Warning: The returned `TokenItem` has a `BlockchainNetwork` with no derivation path (`nil`). Callers that
    ///   need a derivation-correct item (e.g. to add the token to a wallet) must enrich it themselves.
    nonisolated func cryptoCurrency(for currency: ExpressCurrency, supportedBlockchains: Set<Blockchain>) -> TokenItem?

    /// - Note: Fires (and awaits) a load on a cache miss.
    /// - Warning: The returned `TokenItem` has a `BlockchainNetwork` with no derivation path (`nil`). Callers that
    ///   need a derivation-correct item (e.g. to add the token to a wallet) must enrich it themselves.
    func cryptoCurrency(for currency: ExpressCurrency, supportedBlockchains: Set<Blockchain>) async -> TokenItem?
}
