//
//  WalletConnectStabilityUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemAccessibilityIdentifiers

final class WalletConnectStabilityUITests: BaseTestCase {
    let qaToolsClient = QAToolsClient()

    func testPasteInvalidURIs_ShowsErrorAndStaysOnQRScan() throws {
        setAllureId(9037)

        let invalidInputs: [(name: String, value: String)] = [
            ("Random garbage", "not-a-uri-just-text-12345"),
            ("Non-WC URL", "https://example.com/page?x=1"),
            ("WC v1 URI", "wc:abc-topic-xyz@1?bridge=https%3A%2F%2Fbridge.example%2F&key=deadbeef"),
        ]

        UIPasteboard.general.string = invalidInputs[0].value
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()

        DetailsScreen(app)
            .openWalletConnections()
            .tapNewConnection()
            .waitForQRScannerScreenToBeVisible()

        let qr = WalletConnectQRScanScreen(app)

        for (index, input) in invalidInputs.enumerated() {
            XCTContext.runActivity(named: "Variant \(index + 1): \(input.name)") { _ in
                if index > 0 {
                    UIPasteboard.general.string = input.value
                }

                qr.pasteAndExpectError()
                    .assertConnectionSheetIsNotVisible()

                if index < invalidInputs.count - 1 {
                    qr.waitForErrorToastToDisappear()
                }
            }
        }

        XCTAssertEqual(app.state, .runningForeground, "App must remain running (no crash)")
        qr.waitForQRScannerScreenToBeVisible()
    }

    func testRepeatedConnectDisconnect_StaysStable() throws {
        setAllureId(9040)

        let iterations = 3

        UIPasteboard.general.string = stripScheme(fetchURI())
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()

        DetailsScreen(app).openWalletConnections()
        let connections = WalletConnectionsScreen(app)

        for i in 1 ... iterations {
            XCTContext.runActivity(named: "Iteration \(i)/\(iterations)") { _ in
                if i > 1 {
                    UIPasteboard.general.string = stripScheme(fetchURI())
                }

                connections
                    .tapNewConnection()
                    .waitForQRScannerScreenToBeVisible()
                    .tapPasteButton()
                    .waitForConnectionProposalBottomSheetToBeVisible()
                    .tapConnectionButton()

                let dAppRows = app.buttons.matching(identifier: WalletConnectAccessibilityIdentifiers.dAppRow)
                XCTAssertTrue(
                    dAppRows.firstMatch.waitForExistence(timeout: .robustUIUpdate),
                    "dApp row should appear after connect (iteration \(i))"
                )
                XCTAssertEqual(
                    dAppRows.count,
                    1,
                    "Exactly one dApp connection expected after iteration \(i), got \(dAppRows.count)"
                )

                connections
                    .tapFirstDAppRow()
                    .waitForConnectedAppBottomSheetToBeVisible()
                    .tapDisconnectButton()
                    .waitForEmptyConnectionsList()
            }
        }

        XCTAssertEqual(
            app.state,
            .runningForeground,
            "App must remain running after \(iterations) connect/disconnect iterations"
        )
    }

    func testConnectToUnsupportedDApp_ShowsUnsupportedError() throws {
        setAllureId(9066)

        // Host from ReownWalletConnectDAppDataService.unsupportedDAppHosts blacklist.
        let unsupportedDAppURL = "https://dydx.trade/test"

        let wcURI = fetchURI(dAppURL: unsupportedDAppURL, dAppName: "dYdX")
        UIPasteboard.general.string = stripScheme(wcURI)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()

        DetailsScreen(app)
            .openWalletConnections()
            .tapNewConnection()
            .waitForQRScannerScreenToBeVisible()
            .tapPasteButton()

        WalletConnectErrorScreen(app)
            .waitForErrorViewToBeVisible()
            .tapGotItButton()

        XCTAssertEqual(
            app.state,
            .runningForeground,
            "App must remain running after unsupported dApp error dismiss"
        )

        WalletConnectionsScreen(app)
            .waitForEmptyConnectionsList()
    }

    private func fetchURI(dAppURL: String? = nil, dAppName: String? = nil) -> String {
        let uri = qaToolsClient.getWCURISync(
            network: .ethereum,
            uriScheme: .tangem,
            dAppURL: dAppURL,
            dAppName: dAppName
        )
        XCTAssert(!uri.isEmpty, "WC URI from qa-tools must not be empty")
        return uri
    }

    private func stripScheme(_ uri: String) -> String {
        uri.replacingOccurrences(of: "\(WCURIScheme.tangem.rawValue)?uri=", with: "")
    }
}
