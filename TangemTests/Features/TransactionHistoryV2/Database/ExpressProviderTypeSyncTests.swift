//
//  ExpressProviderTypeSyncTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemFoundation
@testable import TangemExpress
@testable import TangemAppDatabase

@Suite("Express provider type DB literals stay in sync with the domain")
struct ExpressProviderTypeSyncTests {
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
}
