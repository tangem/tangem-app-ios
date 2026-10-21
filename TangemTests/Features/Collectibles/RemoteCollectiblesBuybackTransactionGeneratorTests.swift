//
//  RemoteCollectiblesBuybackTransactionGeneratorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("RemoteCollectiblesBuybackTransactionGenerator")
struct RemoteCollectiblesBuybackTransactionGeneratorTests {
    typealias SUT = RemoteCollectiblesBuybackTransactionGenerator

    @Test("Asks to sell the card from the owner to the vault on behalf of the wallet")
    func asksForSaleFromOwnerToVault() async throws {
        let (sut, requester) = makeSUT()

        _ = try await sut.generate(nftAddress: "nft-1", fromAddress: "owner", toAddress: "vault")

        guard case .generateBuybackData(let request, let userWalletID)? = requester.targets.first else {
            Issue.record("Expected the buyback-data request, got \(requester.targets)")
            return
        }

        #expect(request.fromAddress == "owner")
        #expect(request.toAddress == "vault")
        #expect(request.nftAddress == "nft-1")
        #expect(userWalletID == "wallet-1")
        #expect(requester.targets.count == 1)
    }

    @Test("Maps the payout by the token decimals and decodes the transaction bytes")
    func mapsTransaction() async throws {
        let (sut, _) = makeSUT()

        let transaction = try await sut.generate(nftAddress: "nft-1", fromAddress: "owner", toAddress: "vault")

        let expected = CollectiblesBuybackTransaction(
            buybackID: "bb-1",
            memo: "order-1:buyback",
            amount: Decimal(string: "15.5")!,
            transaction: Data([1, 2, 3])
        )
        #expect(transaction == expected)
    }

    @Test("A malformed payout or transaction is rejected", arguments: [
        (toAmount: "15500000", tx: "not base64!"),
        (toAmount: "fifteen", tx: "AQID"),
        (toAmount: "-15500000", tx: "AQID"),
        (toAmount: "15500000abc", tx: "AQID"),
        (toAmount: " 15500000", tx: "AQID"),
        (toAmount: "1.5e7", tx: "AQID"),
        (toAmount: "0x10", tx: "AQID"),
        (toAmount: "0", tx: "AQID"),
    ])
    func rejectsMalformedTransaction(toAmount: String, tx: String) async {
        let (sut, _) = makeSUT(toAmount: toAmount, tx: tx)

        await #expect(throws: CollectiblesAPIService.Error.self) {
            try await sut.generate(nftAddress: "nft-1", fromAddress: "owner", toAddress: "vault")
        }
    }

    @Test("A payout in decimals no token uses is rejected", arguments: [-1, 19, 300])
    func rejectsUnsupportedDecimals(toDecimals: Int) async {
        let (sut, _) = makeSUT(toDecimals: toDecimals)

        await #expect(throws: CollectiblesAPIService.Error.self) {
            try await sut.generate(nftAddress: "nft-1", fromAddress: "owner", toAddress: "vault")
        }
    }
}

// MARK: - Helpers

private extension RemoteCollectiblesBuybackTransactionGeneratorTests {
    func makeSUT(toAmount: String = "15500000", tx: String = "AQID", toDecimals: Int = 6) -> (SUT, APIRequesterStub) {
        let response = #"{"buybackId":"bb-1","txData":{"memo":"order-1:buyback","toDecimals":\#(toDecimals),"toAmount":"\#(toAmount)","tx":"\#(tx)"}}"#
        let requester = APIRequesterStub(response: response)
        return (SUT(userWalletID: "wallet-1", requester: requester), requester)
    }
}

// MARK: - Stubs

private final class APIRequesterStub: CollectiblesAPIRequesting {
    private(set) var targets: [CollectiblesAPITarget.Target] = []

    private let response: String

    init(response: String) {
        self.response = response
    }

    func request<T: Decodable>(_ target: CollectiblesAPITarget.Target) async throws -> T {
        targets.append(target)
        return try JSONDecoder().decode(T.self, from: Data(response.utf8))
    }
}
