//
//  JointAccountsNetworkMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

/// What the endpoint answers with, read the way the API service reads it and turned into what the app keeps.
@Suite("Tests for reading a joint account off the endpoint")
struct JointAccountsNetworkMapperTests {
    private let mapper = JointAccountsNetworkMapper()

    @Test("A freshly created account arrives without an address and with an invite per free slot")
    func createdAccountIsRead() throws {
        let response: JointAccountsDTO.Create.Response = try Self.decode(Constants.createdAccountJSON)

        let result = mapper.mapToCreationResult(from: response)

        #expect(result.account.cryptoAccountId == "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A")
        #expect(result.account.membersCount == 3)
        #expect(result.account.threshold == 2)
        #expect(result.account.address == nil)
        #expect(result.account.status == .pending)
        #expect(result.account.members.map(\.role) == [.creator])
        #expect(result.invites.map(\.id) == ["A1B2C3", "D4E5F6"])
    }

    @Test("The address the whole composition adds up to is the one that gets stored")
    func safeAddressIsRead() throws {
        let response: JointAccountsDTO.List.Response = try Self.decode(Constants.confirmingAccountsJSON)

        let accounts = mapper.mapToJointAccounts(from: response)

        #expect(accounts.count == 1)
        #expect(accounts.first?.address == "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b")
        #expect(accounts.first?.status == .confirming)
        #expect(accounts.first?.members.map(\.name) == ["Alice", "Bob"])
        #expect(accounts.first?.members.map(\.role) == [.creator, .member])
    }

    @Test("An empty list is a list and not a failure")
    func emptyListIsRead() throws {
        let response: JointAccountsDTO.List.Response = try Self.decode(#"{"jointAccounts":[]}"#)

        #expect(mapper.mapToJointAccounts(from: response).isEmpty)
    }

    @Test(
        "A status the contract names is read as that status",
        arguments: [
            ("pending", JointAccountStatus.pending),
            ("confirming", .confirming),
            ("active", .active),
            ("cancelled", .cancelled),
        ]
    )
    func namedStatusIsRead(rawStatus: String, expected: JointAccountStatus) throws {
        let response: JointAccountsDTO.List.Response = try Self.decode(Constants.accountsJSON(status: rawStatus))

        #expect(mapper.mapToJointAccounts(from: response).map(\.status) == [expected])
    }

    @Test("A status this version has never heard of costs nothing but itself")
    func unfamiliarStatusIsRead() throws {
        let response: JointAccountsDTO.List.Response = try Self.decode(Constants.accountsJSON(status: "settling"))

        #expect(mapper.mapToJointAccounts(from: response).map(\.status) == [.unknown("settling")])
    }

    @Test("A stored status survives a round trip, whether this version knows it or not")
    func statusRoundTripsThroughStorage() throws {
        for status in [JointAccountStatus.pending, .confirming, .active, .cancelled, .unknown("settling")] {
            let encoded = try JSONEncoder().encode(status)

            #expect(try JSONDecoder().decode(JointAccountStatus.self, from: encoded) == status)
        }
    }

    @Test("An invite reports the settings in the very shape that joining signs back")
    func invitePreviewIsRead() throws {
        let response: JointAccountsDTO.InvitePreview.Response = try Self.decode(Constants.invitePreviewJSON)

        let preview = mapper.mapToInvitePreview(from: response)

        #expect(preview.creator == JointAccountInvitePreview.Creator(name: "Alice", address: "0x7e5fB2c1A9d3E5F70241C6b8A91cD9c1E7F45bdf"))
        #expect(preview.config == JointAccountSignedConfig(name: "Family", icon: "Family", iconColor: "Azure", membersCount: 3, threshold: 2))

        let canonical = try JointAccountDerivationUtils.canonicalPayload(of: preview.config)

        #expect(String(decoding: canonical, as: UTF8.self) == Constants.expectedCanonicalConfig)
    }

    @Test("A signature travels as a prefixed hex string")
    func signatureIsWritten() {
        let blob = JointAccountJoinBlob(payload: Constants.joinPayload, signature: Data([0x01, 0xAB, 0xFF]))

        #expect(mapper.mapToRequest(from: blob).signature == "0x01ABFF")
    }
}

// MARK: - Helpers

private extension JointAccountsNetworkMapperTests {
    /// Mirrors the decoder `CommonTangemApiService` reads these endpoints with: the joint accounts contract speaks
    /// camelCase, which the snake-case strategy leaves alone for want of an underscore to split on.
    static func decode<T: Decodable>(_ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(T.self, from: Data(json.utf8))
    }
}

// MARK: - Constants

private extension JointAccountsNetworkMapperTests {
    enum Constants {
        static let createdAccountJSON = """
        {
          "cryptoAccountId": "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A",
          "membersCount": 3,
          "threshold": 2,
          "safeAddress": null,
          "status": "pending",
          "members": [
            { "name": "Alice", "address": "0x7e5fB2c1A9d3E5F70241C6b8A91cD9c1E7F45bdf", "role": "creator" }
          ],
          "invites": [{ "id": "A1B2C3" }, { "id": "D4E5F6" }]
        }
        """

        static let confirmingAccountsJSON = """
        {
          "jointAccounts": [
            {
              "cryptoAccountId": "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A",
              "membersCount": 2,
              "threshold": 2,
              "safeAddress": "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b",
              "status": "confirming",
              "members": [
                { "name": "Alice", "address": "0x7e5fB2c1A9d3E5F70241C6b8A91cD9c1E7F45bdf", "role": "creator" },
                { "name": "Bob", "address": "0x2b5aD9c1E7F40638B2c1A9d3E5F70241C6b8A91c", "role": "member" }
              ]
            }
          ]
        }
        """

        static func accountsJSON(status: String) -> String {
            """
            {
              "jointAccounts": [
                {
                  "cryptoAccountId": "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A",
                  "membersCount": 2,
                  "threshold": 2,
                  "safeAddress": null,
                  "status": "\(status)",
                  "members": []
                }
              ]
            }
            """
        }

        static let invitePreviewJSON = """
        {
          "config": {
            "name": "Family",
            "icon": "Family",
            "iconColor": "Azure",
            "membersCount": 3,
            "threshold": 2
          },
          "creator": {
            "name": "Alice",
            "address": "0x7e5fB2c1A9d3E5F70241C6b8A91cD9c1E7F45bdf"
          }
        }
        """

        static let expectedCanonicalConfig = """
        {"icon":"Family","iconColor":"Azure","membersCount":3,"name":"Family","threshold":2}
        """

        static let joinPayload = JointAccountJoinPayload(
            inviteId: "A1B2C3",
            config: JointAccountSignedConfig(name: "Family", icon: "Family", iconColor: "Azure", membersCount: 3, threshold: 2),
            member: JointAccountSignedMember(
                walletId: "9A3E7C1B5D2F8064A2C4E6B8D0F2A4C6E8B0D2F4A6C8E0B2D4F6A8C0E2B4D6F8",
                name: "Bob",
                address: "0x2b5aD9c1E7F40638B2c1A9d3E5F70241C6b8A91c",
                derivation: 7
            )
        )
    }
}
