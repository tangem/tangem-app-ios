//
//  AddressBookDTOTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("AddressBookDTO")
struct AddressBookDTOTests {
    private static let updatedAtISO8601 = "2026-06-17T12:34:56.789Z"

    // MARK: - UpdateRequest wire contract

    @Test
    func updateRequestEncodesBinaryFieldsUnderCamelCaseKeys() throws {
        let request = AddressBookDTO.UpdateRequest(
            version: "1.0",
            nonce: "ABAB",
            ciphertext: "DEADBEEF",
            authTag: "CDCD"
        )

        let json = try JSONDecoder().decode([String: String].self, from: JSONEncoder().encode(request))

        #expect(json["authTag"] == "CDCD")
        #expect(json["tag"] == nil)
        #expect(json["nonce"] == "ABAB")
        #expect(json["ciphertext"] == "DEADBEEF")
        #expect(json["version"] == "1.0")
        #expect(json.count == 4)
    }

    // MARK: - Response.Item decoding

    @Test
    func decodesSyncResponseItemFromFixedJSON() throws {
        let responseJSON = """
        {
          "items": [
            {
              "walletId": "AA11",
              "etag": "etag-7",
              "version": "1.0",
              "updatedAt": "\(Self.updatedAtISO8601)",
              "nonce": "BB22",
              "ciphertext": "CC33",
              "authTag": "DD44"
            }
          ]
        }
        """

        let response = try JSONDecoder().decode(AddressBookDTO.Response.self, from: Data(responseJSON.utf8))
        let item = try #require(response.items.first)

        #expect(response.items.count == 1)
        #expect(item.walletId == "AA11")
        #expect(item.etag == "etag-7")
        #expect(item.version == "1.0")
        #expect(item.updatedAt == Self.updatedAtISO8601)
        #expect(item.nonce == "BB22")
        #expect(item.ciphertext == "CC33")
        #expect(item.authTag == "DD44")
    }
}
