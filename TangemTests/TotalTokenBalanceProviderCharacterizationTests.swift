//
//  TotalTokenBalanceProviderCharacterizationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

/// Characterizes the legacy `TotalTokenBalanceProvider` fold over the full state-pair table.
/// Delete together with the legacy provider when the `totalTokenBalanceV2` toggle is removed.
@Suite("TotalTokenBalanceProvider characterization")
struct TotalTokenBalanceProviderCharacterizationTests {
    @Test(arguments: TotalTokenBalanceFoldTable.rows)
    func foldMatchesCurrentBehavior(row: FoldRow) {
        let sut = makeSUT(available: row.available, staking: row.staking, blockchain: .ethereum(testnet: false))

        row.expected.verify(against: sut.balanceType)
    }

    @Test(arguments: TotalTokenBalanceFoldTable.cardanoRows)
    func cardanoFoldMatchesCurrentBehavior(row: FoldRow) {
        let sut = makeSUT(available: row.available, staking: row.staking, blockchain: .cardano(extended: false))

        row.expected.verify(against: sut.balanceType)
    }
}

// MARK: - Helpers

private func makeSUT(
    available: TokenBalanceType,
    staking: TokenBalanceType,
    blockchain: Blockchain
) -> TotalTokenBalanceProvider {
    TotalTokenBalanceProvider(
        tokenItem: .blockchain(.init(blockchain, derivationPath: nil)),
        availableBalanceProvider: MutableTokenBalanceProviderMock(initialState: available),
        stakingBalanceProvider: MutableTokenBalanceProviderMock(initialState: staking)
    )
}
