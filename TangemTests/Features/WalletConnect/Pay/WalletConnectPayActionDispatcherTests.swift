//
//  WalletConnectPayActionDispatcherTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

final class WalletConnectPayActionDispatcherTests: XCTestCase {
    func testUnsupportedMethodFailsBeforeSigning() async {
        let dispatcher = WalletConnectPayActionDispatcher(
            userWalletModel: UserWalletModelMock(),
            accountId: ""
        )

        do {
            _ = try await dispatcher.dispatch([
                WalletConnectPayAction(walletRpc: WalletConnectPayWalletRPC(
                    chainId: "eip155:1",
                    method: "wallet_unsupportedMethod",
                    params: "[]"
                )),
            ])
            XCTFail("Expected unsupported method error")
        } catch WalletConnectTransactionRequestProcessingError.unsupportedMethod(let method) {
            XCTAssertEqual(method, "wallet_unsupportedMethod")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
