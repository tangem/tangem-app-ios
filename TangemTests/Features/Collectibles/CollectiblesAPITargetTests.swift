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
        #expect(makeTarget(.generateTx(Self.generateTxRequest, userWalletID: "wallet-1")).path == "api/v1/collectible/generateTx")
        #expect(makeTarget(.submitTx(Self.submitTxRequest, userWalletID: "wallet-1")).path == "api/v1/collectible/submitTx")
    }

    @Test("Catalogue is read with GET, transactions are sent with POST")
    func methods() {
        #expect(makeTarget(.categories).method == .get)
        #expect(makeTarget(.machines(.init())).method == .get)
        #expect(makeTarget(.machine(externalID: "pokemon_50")).method == .get)
        #expect(makeTarget(.generateTx(Self.generateTxRequest, userWalletID: "wallet-1")).method == .post)
        #expect(makeTarget(.submitTx(Self.submitTxRequest, userWalletID: "wallet-1")).method == .post)
    }

    @Test("Only the transaction calls carry the user-id header")
    func userIDHeader() {
        #expect(makeTarget(.categories).headers == nil)
        #expect(makeTarget(.machines(.init())).headers == nil)
        #expect(makeTarget(.machine(externalID: "pokemon_50")).headers == nil)
        #expect(makeTarget(.generateTx(Self.generateTxRequest, userWalletID: "wallet-1")).headers == ["user-id": "wallet-1"])
        #expect(makeTarget(.submitTx(Self.submitTxRequest, userWalletID: "wallet-2")).headers == ["user-id": "wallet-2"])
    }

    @Test("generateTx: body carries the addresses and the machine, turbo mode is omitted when absent")
    func generateTxBody() throws {
        let body = try jsonBody(makeTarget(.generateTx(Self.generateTxRequest, userWalletID: "wallet-1")).task)

        #expect(body["fromAddress"] as? String == "owner")
        #expect(body["collectibleType"] as? String == "pokemon_50")
        #expect(body["toAddress"] as? String == "cold")
        #expect(body["turboMode"] == nil)
        #expect(body.count == 3)
    }

    @Test("generateTx: turbo mode is nested with its flag and buyback address")
    func generateTxTurboModeBody() throws {
        let request = CollectiblesDTO.GenerateTxRequest(
            fromAddress: "owner",
            collectibleType: "pokemon_50",
            toAddress: "cold",
            turboMode: .init(enabled: true, buybackAddress: "buyback")
        )

        let body = try jsonBody(makeTarget(.generateTx(request, userWalletID: "wallet-1")).task)
        let turboMode = try #require(body["turboMode"] as? [String: Any])

        #expect(turboMode["enabled"] as? Bool == true)
        #expect(turboMode["buybackAddress"] as? String == "buyback")
    }

    @Test("submitTx: body carries the signed transaction only")
    func submitTxBody() throws {
        let body = try jsonBody(makeTarget(.submitTx(Self.submitTxRequest, userWalletID: "wallet-1")).task)

        #expect(body["signedTxData"] as? String == "c2lnbmVk")
        #expect(body.count == 1)
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
}

// MARK: - Helpers

private extension CollectiblesAPITargetTests {
    func makeTarget(_ target: CollectiblesAPITarget.Target) -> CollectiblesAPITarget {
        CollectiblesAPITarget(baseURL: URL(string: "https://example.com")!, target: target)
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

    static let generateTxRequest = CollectiblesDTO.GenerateTxRequest(fromAddress: "owner", collectibleType: "pokemon_50", toAddress: "cold")
    static let submitTxRequest = CollectiblesDTO.SubmitTxRequest(signedTxData: "c2lnbmVk")

    enum TestError: Error { case notRequestParameters, notJSONEncodable, notJSONObject }
}
