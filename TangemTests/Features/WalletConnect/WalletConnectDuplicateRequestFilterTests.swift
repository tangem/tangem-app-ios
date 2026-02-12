//
//  WalletConnectDuplicateRequestFilterTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import ReownWalletKit
@testable import Tangem

struct WalletConnectDuplicateRequestFilterTests {
    @Test
    func shouldAllowRequestProcessingWhenFilterIsEmpty() async throws {
        let sut = Self.makeSUT()
        let request = try Self.makeAnyRequest()

        #expect(await sut.isProcessingAllowed(for: request))
    }

    @Test
    func shouldForbidDuplicateRequestProcessingWithShortInterval() async throws {
        let sut = Self.makeSUT()
        let request = try Self.makeAnyRequest()
        let duplicateRequest = try Self.makeAnyRequest()

        #expect(await sut.isProcessingAllowed(for: request))
        #expect(await sut.isProcessingAllowed(for: duplicateRequest) == false)
    }

    private static func makeSUT() -> WalletConnectDuplicateRequestFilter {
        WalletConnectDuplicateRequestFilter()
    }

    private static func makeAnyRequest() throws -> ReownWalletKit.Request {
        let anyBlockchain = ReownWalletKit.Blockchain(namespace: "eip155", reference: "1")

        return try ReownWalletKit.Request(
            topic: "anyTopic",
            method: "eth_sendTransaction",
            params: AnyCodable(any: ["anyMessage", "anyAddress"]),
            chainId: try #require(anyBlockchain)
        )
    }
}
