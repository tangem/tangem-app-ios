//
//  YieldModuleBlockchainAvailabilityTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("YieldModuleBlockchainAvailability")
struct YieldModuleBlockchainAvailabilityTests {
    typealias SUT = YieldModuleBlockchainAvailability

    @Test("Monad is hidden while Merkl incentives are off", arguments: [false, true])
    func monadFollowsMerklIncentives(isMerklIncentivesAvailable: Bool) {
        let sut = SUT(isMerklIncentivesAvailable: isMerklIncentivesAvailable)

        #expect(sut.isAvailable(on: .monad(testnet: false)) == isMerklIncentivesAvailable)
        #expect(sut.isAvailable(chainId: 143) == isMerklIncentivesAvailable)
    }

    @Test(
        "Other yield chains stay available regardless of Merkl incentives",
        arguments: [
            Blockchain.ethereum(testnet: false),
            .polygon(testnet: false),
            .arbitrum(testnet: false),
            .bsc(testnet: false),
        ],
        [false, true]
    )
    func otherChainsIgnoreMerklIncentives(blockchain: Blockchain, isMerklIncentivesAvailable: Bool) {
        let sut = SUT(isMerklIncentivesAvailable: isMerklIncentivesAvailable)

        #expect(sut.isAvailable(on: blockchain))
        #expect(sut.isAvailable(chainId: blockchain.chainId))
    }

    @Test("Market without a chain id is kept")
    func missingChainIdIsAvailable() {
        #expect(SUT(isMerklIncentivesAvailable: false).isAvailable(chainId: nil))
    }
}
