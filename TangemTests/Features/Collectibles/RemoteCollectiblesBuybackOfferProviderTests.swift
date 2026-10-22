//
//  RemoteCollectiblesBuybackOfferProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("RemoteCollectiblesBuybackOfferProvider")
struct RemoteCollectiblesBuybackOfferProviderTests {
    typealias SUT = RemoteCollectiblesBuybackOfferProvider

    @Test("Asks for the offer of the card on behalf of the wallet")
    func asksForCardOffer() async throws {
        let (sut, requester) = makeSUT(response: #"{"buybackAvailable":false}"#)

        _ = try await sut.load(nftAddress: "nft-1")

        guard case .buybackAvailability(let request, let userWalletID)? = requester.targets.first else {
            Issue.record("Expected the availability request, got \(requester.targets)")
            return
        }

        #expect(request.nftAddress == "nft-1")
        #expect(userWalletID == "wallet-1")
        #expect(requester.targets.count == 1)
    }

    @Test("An available buyback becomes an offer with its price in dollars")
    func mapsPriceToDollars() async throws {
        let (sut, _) = makeSUT(response: #"{"buybackAvailable":true,"buybackAmount":1550}"#)

        let offer = try await sut.load(nftAddress: "nft-1")

        #expect(offer?.amount == Decimal(string: "15.5"))
    }

    @Test("A buyback the backend does not offer is no offer")
    func mapsUnavailableOffer() async throws {
        let (sut, _) = makeSUT(response: #"{"buybackAvailable":false}"#)

        let offer = try await sut.load(nftAddress: "nft-1")

        #expect(offer == nil)
    }

    @Test("An available buyback without a positive price is a broken answer, not a free card", arguments: [
        #"{"buybackAvailable":true}"#,
        #"{"buybackAvailable":true,"buybackAmount":0}"#,
        #"{"buybackAvailable":true,"buybackAmount":-1550}"#,
    ])
    func rejectsOfferWithoutPositivePrice(response: String) async {
        let (sut, _) = makeSUT(response: response)

        await #expect(throws: CollectiblesAPIService.Error.self) {
            try await sut.load(nftAddress: "nft-1")
        }
    }
}

// MARK: - Helpers

private extension RemoteCollectiblesBuybackOfferProviderTests {
    func makeSUT(response: String) -> (SUT, APIRequesterStub) {
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
