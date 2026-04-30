//
//  WalletConnectDeeplinkPreserveRuleTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct WalletConnectDeeplinkPreserveRuleTests {
    @Test(arguments: RuleTestCases.Preserved.validWalletConnectDeeplinks)
    func shouldPreserveWalletConnectDeeplinks(testCase: PreserveLogTestCase) {
        let sut = Self.makeSUT()
        assert(preserved: testCase, using: sut)
    }

    @Test(arguments: RuleTestCases.Ignored.invalidDeeplinks)
    func shouldIgnoreNonWalletConnectDeeplinks(testCase: String) {
        let sut = Self.makeSUT()
        assert(ignored: testCase, using: sut)
    }
}

// MARK: - Preserved test cases

private extension RuleTestCases.Preserved {
    private static func deeplinkPlaceholder(for index: UInt = 0) -> String {
        "__PRESERVE_RULE_WC_DEEPLINK_\(index)"
    }

    static let walletConnectDeeplinkRaw: Substring =
        "tangem://wc?uri=wc%3Aa4f57e0493f84cfc7168a91579a18c5d9587dd1dd2d40efbe1cd916570399710%402%3Frelay-protocol%3Dirn%26symKey%3D57285434b30502b8991753225668f667e7c529926f007cec30652861ac11d8a4%26expiryTimestamp%3D1750166958"

    static let walletConnectDeeplinkRaw2: Substring =
        "tangem://wc?uri=wc%3A08018d08454c05ed4a5714cf74df3279f95648a9c216b68380599f9120a03a68%402%3FexpiryTimestamp%3D1777542409%26relay-protocol%3Dirn%26symKey%3Da5f72962c597402f36964378228212aad395b1fb705f6259ae6bf96aef944c40"

    static let walletConnectDeeplinkRaw3: Substring =
        "tangem://wc?uri=wc%3A3be77ffcbcc5d03a8a6e338ebfda06f1652b97d3fc5a50383214b489a337afce%402%3FexpiryTimestamp%3D1777542582%26relay-protocol%3Dirn%26symKey%3D0472702c3da74bbe17ece3b731350846e6043bc32c9059594eede7819b9c2a11"

    static let walletConnectDeeplinkWithoutExpiryRaw: Substring =
        #"tangem://wc?uri=wc%3Aa4f57e0493f84cfc7168a91579a18c5d9587dd1dd2d40efbe1cd916570399710%402%3FsymKey%3D57285434b30502b8991753225668f667e7c529926f007cec30652861ac11d8a4%26relay-protocol%3Dirn%26methods%3Dpersonal_sign"#

    static let walletConnectDeeplink = PreserveLogTestCase(
        originalLog: "Received deeplink: \(walletConnectDeeplinkRaw)",
        preservedLog: "Received deeplink: \(deeplinkPlaceholder())",
        capturedValues: [walletConnectDeeplinkRaw]
    )

    static let walletConnectDeeplink2 = PreserveLogTestCase(
        originalLog: String(walletConnectDeeplinkRaw2),
        preservedLog: deeplinkPlaceholder(),
        capturedValues: [walletConnectDeeplinkRaw2]
    )

    static let walletConnectDeeplink3 = PreserveLogTestCase(
        originalLog: "Received deeplink: \(walletConnectDeeplinkRaw3)",
        preservedLog: "Received deeplink: \(deeplinkPlaceholder())",
        capturedValues: [walletConnectDeeplinkRaw3]
    )

    static let walletConnectDeeplinkWithoutExpiry = PreserveLogTestCase(
        originalLog: "prefix \(walletConnectDeeplinkWithoutExpiryRaw) suffix",
        preservedLog: "prefix \(deeplinkPlaceholder()) suffix",
        capturedValues: [walletConnectDeeplinkWithoutExpiryRaw]
    )

    static let validWalletConnectDeeplinks = [
        RuleTestCases.Preserved.walletConnectDeeplink,
        RuleTestCases.Preserved.walletConnectDeeplink2,
        RuleTestCases.Preserved.walletConnectDeeplink3,
        RuleTestCases.Preserved.walletConnectDeeplinkWithoutExpiry,
    ]
}

// MARK: - Ignored test cases

private extension RuleTestCases.Ignored {
    static let nonWalletConnectTangemDeeplink =
        #"tangem://swap?uri=wc%3Aa4f57e0493f84cfc7168a91579a18c5d9587dd1dd2d40efbe1cd916570399710%402%3Frelay-protocol%3Dirn%26symKey%3D57285434b30502b8991753225668f667e7c529926f007cec30652861ac11d8a4"#

    static let rawWalletConnectURI =
        #"wc%3Aa4f57e0493f84cfc7168a91579a18c5d9587dd1dd2d40efbe1cd916570399710%402%3Frelay-protocol%3Dirn%26symKey%3D57285434b30502b8991753225668f667e7c529926f007cec30652861ac11d8a4"#

    static let invalidDeeplinks = [
        RuleTestCases.Ignored.nonWalletConnectTangemDeeplink,
        RuleTestCases.Ignored.rawWalletConnectURI,
    ]
}

private extension WalletConnectDeeplinkPreserveRuleTests {
    static func makeSUT() -> PreserveRule {
        PreserveRule.walletConnectDeeplink
    }
}
