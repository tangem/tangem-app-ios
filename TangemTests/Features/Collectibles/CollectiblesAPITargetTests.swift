//
//  CollectiblesAPITargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import Tangem

@Suite("CollectiblesAPITarget")
final class CollectiblesAPITargetTests {
    @Test("Paths")
    func paths() {
        #expect(makeTarget(.categories).path == "api/v1/machine/categories")
        #expect(makeTarget(.machines(.init())).path == "api/v1/machine/machines")
        #expect(makeTarget(.machine(externalID: "pokemon_50")).path == "api/v1/machine/pokemon_50")
    }

    @Test("Catalogue is read with GET")
    func methods() {
        #expect(makeTarget(.categories).method == .get)
        #expect(makeTarget(.machines(.init())).method == .get)
        #expect(makeTarget(.machine(externalID: "pokemon_50")).method == .get)
    }

    @Test("Only the calls the backend scopes to a wallet carry the user-id header")
    func userIDHeader() {
        #expect(makeTarget(.categories).headers == nil)
        #expect(makeTarget(.machines(.init())).headers == nil)
        #expect(makeTarget(.machine(externalID: "pokemon_50")).headers == nil)
        #expect(makeTarget(.machineNfts(externalID: "pokemon_50", .init(page: 1, limit: 50), userWalletID: "wallet-3")).headers == ["user-id": "wallet-3"])
    }

    @Test("machines: empty request sends no query")
    func machinesEmptyParameters() throws {
        let parameters = try queryParameters(makeTarget(.machines(.init())).task)

        #expect(parameters.isEmpty)
    }

    @Test("machines: only non-nil fields become query items")
    func machinesPartialParameters() throws {
        let request = CollectiblesDTO.MachinesRequest(categoryID: "cat-1", limit: 20)

        let parameters = try queryParameters(makeTarget(.machines(request)).task)

        #expect(parameters["categoryId"] as? String == "cat-1")
        #expect(parameters["limit"] as? Int == 20)
        #expect(parameters["search"] == nil)
        #expect(parameters["cursor"] == nil)
    }

    @Test("machines: full request sends all four query items")
    func machinesFullParameters() throws {
        let request = CollectiblesDTO.MachinesRequest(categoryID: "cat-1", search: "pikachu", limit: 20, cursor: "next")

        let parameters = try queryParameters(makeTarget(.machines(request)).task)

        #expect(parameters["categoryId"] as? String == "cat-1")
        #expect(parameters["search"] as? String == "pikachu")
        #expect(parameters["limit"] as? Int == 20)
        #expect(parameters["cursor"] as? String == "next")
        #expect(parameters.count == 4)
    }

    @Test("generate-purchase-tx: Turbo mode is sent as a nested object")
    func generatePurchaseTurboMode() throws {
        let request = CollectiblesDTO.GeneratePurchaseTxRequest(
            fromAddress: "from",
            machineID: "pokemon_50",
            toAddress: "to",
            turboMode: CollectiblesDTO.TurboMode(enabled: true, buybackAddress: "buyback")
        )

        let body = try jsonObject(request)
        let turboMode = body["turboMode"] as? [String: Any]

        #expect(turboMode?["enabled"] as? Bool == true)
        #expect(turboMode?["buybackAddress"] as? String == "buyback")
    }

    @Test("Turbo off sends no turboMode, Turbo on sends an enabled one with its address")
    func turboModeMapping() {
        let off = CollectiblesAPIService.Mapper.mapToTurboMode(.off)
        let on = CollectiblesAPIService.Mapper.mapToTurboMode(.on(buybackAddress: "buyback"))

        #expect(off == nil)
        #expect(on?.enabled == true)
        #expect(on?.buybackAddress == "buyback")
    }

    @Test("generate-purchase-tx: no Turbo mode leaves the key out")
    func generatePurchaseWithoutTurboMode() throws {
        let request = CollectiblesDTO.GeneratePurchaseTxRequest(
            fromAddress: "from",
            machineID: "pokemon_50",
            toAddress: "to",
            turboMode: nil
        )

        let body = try jsonObject(request)

        #expect(body["turboMode"] == nil)
        #expect(body["machineId"] as? String == "pokemon_50")
    }

    // MARK: - Buyback

    @Test("Buyback endpoints live under api/v1/buyback")
    func buybackPaths() {
        #expect(makeTarget(.buybackAvailability(.init(nftAddress: "nft-1"), userWalletID: "wallet-1")).path == "api/v1/buyback/available")
        #expect(makeTarget(.generateBuybackData(Self.generateBuybackRequest, userWalletID: "wallet-1")).path == "api/v1/buyback/buyback-data")
        #expect(makeTarget(.buybackTxSent(.init(buybackID: "bb-1", txHash: "hash-1"), userWalletID: "wallet-1")).path == "api/v1/buyback/buyback-tx-sent")
        #expect(makeTarget(.buybackStatus(.init(buybackID: "bb-1"), userWalletID: "wallet-1")).path == "api/v1/buyback/status")
    }

    @Test("Buyback reads use GET and writes use POST")
    func buybackMethods() {
        #expect(makeTarget(.buybackAvailability(.init(nftAddress: "nft-1"), userWalletID: "wallet-1")).method == .get)
        #expect(makeTarget(.generateBuybackData(Self.generateBuybackRequest, userWalletID: "wallet-1")).method == .post)
        #expect(makeTarget(.buybackTxSent(.init(buybackID: "bb-1", txHash: "hash-1"), userWalletID: "wallet-1")).method == .post)
        #expect(makeTarget(.buybackStatus(.init(buybackID: "bb-1"), userWalletID: "wallet-1")).method == .get)
    }

    @Test("Every buyback call is scoped to the wallet")
    func buybackUserIDHeader() {
        let expected = ["user-id": "wallet-1"]

        #expect(makeTarget(.buybackAvailability(.init(nftAddress: "nft-1"), userWalletID: "wallet-1")).headers == expected)
        #expect(makeTarget(.generateBuybackData(Self.generateBuybackRequest, userWalletID: "wallet-1")).headers == expected)
        #expect(makeTarget(.buybackTxSent(.init(buybackID: "bb-1", txHash: "hash-1"), userWalletID: "wallet-1")).headers == expected)
        #expect(makeTarget(.buybackStatus(.init(buybackID: "bb-1"), userWalletID: "wallet-1")).headers == expected)
    }

    @Test("available: the card address travels in the query")
    func buybackAvailabilityQuery() throws {
        let parameters = try queryParameters(makeTarget(.buybackAvailability(.init(nftAddress: "nft-1"), userWalletID: "wallet-1")).task)

        #expect(parameters["nftAddress"] as? String == "nft-1")
        #expect(parameters.count == 1)
    }

    @Test("status: the buyback id travels in the query under the backend's key")
    func buybackStatusQuery() throws {
        let parameters = try queryParameters(makeTarget(.buybackStatus(.init(buybackID: "bb-1"), userWalletID: "wallet-1")).task)

        #expect(parameters["buybackId"] as? String == "bb-1")
        #expect(parameters.count == 1)
    }

    @Test("buyback-data: the three addresses travel in the body")
    func generateBuybackBody() throws {
        let body = try jsonBody(makeTarget(.generateBuybackData(Self.generateBuybackRequest, userWalletID: "wallet-1")).task)

        #expect(body["fromAddress"] as? String == "owner")
        #expect(body["nftAddress"] as? String == "nft-1")
        #expect(body["toAddress"] as? String == "vault")
        #expect(body.count == 3)
    }

    @Test("buyback-tx-sent: the id and the hash travel in the body under the backend's keys")
    func buybackTxSentBody() throws {
        let body = try jsonBody(makeTarget(.buybackTxSent(.init(buybackID: "bb-1", txHash: "hash-1"), userWalletID: "wallet-1")).task)

        #expect(body["buybackId"] as? String == "bb-1")
        #expect(body["txHash"] as? String == "hash-1")
        #expect(body.count == 2)
    }
}

// MARK: - Helpers

private extension CollectiblesAPITargetTests {
    static let generateBuybackRequest = CollectiblesDTO.GenerateBuybackDataRequest(
        fromAddress: "owner",
        nftAddress: "nft-1",
        toAddress: "vault"
    )

    func makeTarget(_ target: CollectiblesAPITarget.Target) -> CollectiblesAPITarget {
        CollectiblesAPITarget(baseURL: URL(string: "https://example.com")!, target: target)
    }

    func jsonObject(_ request: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    func queryParameters(_ task: Moya.Task) throws -> [String: Any] {
        guard case .requestParameters(let parameters, _) = task else {
            throw TestError.notRequestParameters
        }
        return parameters
    }

    func jsonBody(_ task: Moya.Task) throws -> [String: Any] {
        guard case .requestJSONEncodable(let encodable) = task else {
            throw TestError.notJSONEncodable
        }

        let data = try JSONEncoder().encode(encodable)

        guard let body = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TestError.notJSONObject
        }
        return body
    }

    enum TestError: Error { case notRequestParameters, notJSONEncodable, notJSONObject }
}
