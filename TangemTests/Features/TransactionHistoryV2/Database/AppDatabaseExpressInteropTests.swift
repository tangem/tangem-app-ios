//
//  AppDatabaseExpressInteropTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemFoundation
@testable import TangemExpress
@testable import TangemAppDatabase

@Suite("AppDatabase <-> Express contracts and interop")
struct AppDatabaseExpressInteropTests {
    @Test(arguments: ExpressBranch.allCases)
    func databaseTypeValuesMatchDomain(branch: ExpressBranch) {
        // Do not add `default` here, we want exhaustive switch to handle all possible cases of `ExpressBranch`
        let databaseValues = switch branch {
        case .swap:
            ExpressProviderRecord.Values.ProviderType.swap
        case .onramp:
            ExpressProviderRecord.Values.ProviderType.onramp
        }

        #expect(databaseValues.toSet() == branch.supportedProviderTypes.map(\.rawValue).toSet())
    }

    @Test("Coin contract address placeholder literal is pinned")
    func coinContractAddressPlaceholderLiteralIsPinned() {
        #expect(ExpressConstants.coinContractAddress == "0")
    }
}
