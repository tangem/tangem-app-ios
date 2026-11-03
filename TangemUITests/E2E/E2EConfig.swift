//
//  E2EConfig.swift
//  TangemUITests
//
//  Default E2E catalog for local runs; regenerated on CI from qa-tools by
//  scripts/ci/ui-tests/update-e2e-config.sh. A dedicated throwaway test wallet whose token
//  list the suite resets by walletId before each run, so the add-network flow is deterministic.
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum E2EConfig {
    static let testData = E2ETestData(
        seedPhrase: "apology mask middle front stage rather oyster today scrap end close strong",
        walletId: "46255D252ED3808AF7F3F7797D2F2C0E87D8BB80896D0D0366A6EB6E4898CC4B",
        network: E2ENetwork(
            coinId: "polygon-ecosystem-token",
            searchQuery: "POL",
            tokenName: "POL (ex-MATIC)",
            networkName: "Polygon",
            mainScreenToken: "Polygon",
            accountAddresses: [
                "0x3A0078b8407bC5d7C72FAd47F03eb9D315CA252e",
                "0x6c9578665c02Cc3FF16639A7C636f756B085Ce49",
            ]
        )
    )
}
