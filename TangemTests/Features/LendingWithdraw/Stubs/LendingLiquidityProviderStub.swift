//
//  LendingLiquidityProviderStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class LendingLiquidityProviderStub: YieldModuleLendingLiquidityProvider {
    private let results: OSAllocatedUnfairLock<[Result<Decimal, Error>]>
    private let readPositions = OSAllocatedUnfairLock(initialState: [Decimal]())

    convenience init(result: Result<Decimal, Error>) {
        self.init(results: [result])
    }

    init(results: [Result<Decimal, Error>]) {
        self.results = OSAllocatedUnfairLock(initialState: results)
    }

    var positionsRead: [Decimal] {
        readPositions.withLock { $0 }
    }

    func wrappedNative() async throws -> String {
        "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
    }

    func nativePosition() async throws -> Decimal {
        throw LendingLiquidityErrorStub()
    }

    func availableToWithdraw(nativePosition: Decimal) async throws -> Decimal {
        readPositions.withLock { $0.append(nativePosition) }
        let result = results.withLock { $0.count > 1 ? $0.removeFirst() : $0[0] }
        return try result.get()
    }
}

struct LendingLiquidityErrorStub: Error {}
