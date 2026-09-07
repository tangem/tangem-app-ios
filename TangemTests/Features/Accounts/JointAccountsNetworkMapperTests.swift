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
        let response: JointAccountsDTO.Response.JointAccount = try Self.decode(Constants.createdAccountJSON)

        let result = try mapper.mapToCreationResult(from: response)

        #expect(result.account.cryptoAccountId == "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A")
        #expect(result.account.membersCount == 3)
        #expect(result.account.threshold == 2)
        #expect(result.account.status == .pending)
        #expect(result.account.members.map(\.role) == [.creator])
        #expect(result.invites.map(\.id) == ["A1B2C3", "D4E5F6"])
    }

    @Test("The members are read slot for slot, the creator first")
    func membersAreRead() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.confirmingAccountsJSON)

        let accounts = try mapper.mapToJointAccounts(from: response)

        #expect(accounts.count == 1)
        #expect(accounts.first?.status == .confirming)
        #expect(accounts.first?.members.map(\.name) == ["Alice", "Bob"])
        #expect(accounts.first?.members.map(\.role) == [.creator, .member])
        #expect(accounts.first?.members.map(\.inviteId) == [nil, "F0E1D2C3A4B5C6D7"])
    }

    @Test("An empty list is a list and not a failure")
    func emptyListIsRead() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(#"{"jointAccounts":[]}"#)

        #expect(try mapper.mapToJointAccounts(from: response).isEmpty)
    }

    @Test(
        "A status the contract names is read as that status",
        arguments: [
            ("pending", JointAccountStatus.pending),
            ("confirming", .confirming),
            ("cancelled", .cancelled),
        ]
    )
    func namedStatusIsRead(rawStatus: String, expected: JointAccountStatus) throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.accountsJSON(status: rawStatus))

        #expect(try mapper.mapToJointAccounts(from: response).map(\.status) == [expected])
    }

    @Test("An active account is read with the address it lives at")
    func activeStatusCarriesTheAddress() throws {
        let json = Constants.accountsJSON(status: "active", safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b")
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)

        let statuses = try mapper.mapToJointAccounts(from: response).map(\.status)

        #expect(statuses == [.active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b")])
    }

    @Test("An active account without an address is a failure, not a guess")
    func activeStatusWithoutAddressIsRefused() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.accountsJSON(status: "active"))

        #expect(throws: JointAccountsNetworkMapperError.activeAccountWithoutAddress) {
            try mapper.mapToJointAccounts(from: response)
        }
    }

    @Test("A status this version has never heard of costs nothing but itself")
    func unfamiliarStatusIsRead() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.accountsJSON(status: "settling"))

        #expect(try mapper.mapToJointAccounts(from: response).map(\.status) == [.unknown])
    }

    @Test("An answer arriving without a status at all is the contract broken, not the contract grown")
    func missingStatusIsRefused() throws {
        #expect(throws: DecodingError.self) {
            let _: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.accountsJSONWithoutStatus)
        }
    }

    @Test("A stored status survives a round trip, whether this version knows it or not")
    func statusRoundTripsThroughStorage() throws {
        for status in [JointAccountStatus.pending, .confirming, .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), .cancelled, .unknown] {
            let encoded = try JSONEncoder().encode(status)

            #expect(try JSONDecoder().decode(JointAccountStatus.self, from: encoded) == status)
        }
    }

    @Test("An unfinished operation rides inside its account through the listing")
    func operationIsRead() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.activeAccountsWithOperationJSON)

        let operation = try #require(response.jointAccounts.first?.operations?.first)

        #expect(operation.operationId == "0E2F4A6C-8D0B-4C5E-9F1A-2D4B6C8E0F2A")
        #expect(operation.chainId == 1)
        #expect(operation.status == "awaiting_signatures")
        #expect(operation.initiator == "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf")
        #expect(operation.deadline == nil)
        #expect(operation.safeTx.nonce == 7)
        #expect(operation.safeTx.operation == 0)
        #expect(operation.signatures.map(\.state) == ["signed", "declined"])
    }

    @Test("A listing without operations reads the way it did before the endpoint learnt to report them")
    func accountWithoutOperationsIsRead() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.confirmingAccountsJSON)

        #expect(response.jointAccounts.first?.operations == nil)
    }

    @Test("An invite reports the settings in the very shape that joining signs back")
    func invitePreviewIsRead() throws {
        let response: JointAccountsDTO.Response.InvitePreview = try Self.decode(Constants.invitePreviewJSON)

        let preview = mapper.mapToInvitePreview(from: response)

        #expect(preview.creator == JointAccountInvitePreview.Creator(name: "Alice", address: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"))
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
            { "name": "Alice", "address": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", "role": "creator" }
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
              "safeAddress": "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b",
              "status": "confirming",
              "members": [
                { "name": "Alice", "address": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", "role": "creator", "inviteId": null },
                { "name": "Bob", "address": "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c", "role": "member", "inviteId": "F0E1D2C3A4B5C6D7" }
              ]
            }
          ]
        }
        """

        static let activeAccountsWithOperationJSON = """
        {
          "jointAccounts": [
            {
              "cryptoAccountId": "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A",
              "membersCount": 2,
              "threshold": 2,
              "safeAddress": "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b",
              "status": "active",
              "members": [
                { "name": "Alice", "address": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", "role": "creator", "inviteId": null },
                { "name": "Bob", "address": "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c", "role": "member", "inviteId": "F0E1D2C3A4B5C6D7" }
              ],
              "operations": [
                {
                  "operationId": "0E2F4A6C-8D0B-4C5E-9F1A-2D4B6C8E0F2A",
                  "chainId": 1,
                  "safeTx": {
                    "to": "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
                    "value": "0",
                    "data": "0x",
                    "operation": 0,
                    "safeTxGas": "0",
                    "baseGas": "118000",
                    "gasPrice": "1500000000",
                    "gasToken": "0x0000000000000000000000000000000000000000",
                    "refundReceiver": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                    "nonce": 7
                  },
                  "status": "awaiting_signatures",
                  "initiator": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                  "deadline": null,
                  "signatures": [
                    { "address": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", "state": "signed", "at": "2026-09-02T10:15:00Z" },
                    { "address": "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c", "state": "declined", "at": "2026-09-02T10:19:00Z" }
                  ]
                }
              ]
            }
          ]
        }
        """

        static func accountsJSON(status: String, safeAddress: String? = nil) -> String {
            """
            {
              "jointAccounts": [
                {
                  "cryptoAccountId": "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A",
                  "membersCount": 2,
                  "threshold": 2,
                  "safeAddress": \(safeAddress.map { "\"\($0)\"" } ?? "null"),
                  "status": "\(status)",
                  "members": []
                }
              ]
            }
            """
        }

        static let accountsJSONWithoutStatus = """
        {
          "jointAccounts": [
            {
              "cryptoAccountId": "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A",
              "membersCount": 2,
              "threshold": 2,
              "safeAddress": null,
              "members": []
            }
          ]
        }
        """

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
            "address": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
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
