//
//  JointAccountsNetworkMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
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
        #expect(accounts.first?.status == .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"))
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

    @Test("An account awaiting activation is read with the address it is about to be activated at")
    func confirmingStatusCarriesTheAddress() throws {
        let json = Constants.accountsJSON(status: "confirming", safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b")
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)

        let statuses = try mapper.mapToJointAccounts(from: response).map(\.status)

        #expect(statuses == [.confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b")])
    }

    /// Unlike an activated account, which is unusable without the address it is operated at, this one is merely
    /// unactivatable — and refusing it would cost every other account in the answer its refresh.
    @Test("An account awaiting activation without an address is read all the same, with nothing to activate at")
    func confirmingStatusWithoutAddressIsRead() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.accountsJSON(status: "confirming"))

        #expect(try mapper.mapToJointAccounts(from: response).map(\.status) == [.confirming(safeAddress: nil)])
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
        let statuses: [JointAccountStatus] = [
            .pending,
            .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
            .confirming(safeAddress: nil),
            .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
            .cancelled,
            .unknown,
        ]

        for status in statuses {
            let encoded = try JSONEncoder().encode(status)

            #expect(try JSONDecoder().decode(JointAccountStatus.self, from: encoded) == status)
        }
    }

    /// The stage carried no address at all before activation was built, so a record written by such a build names
    /// the case and nothing else — and still has to read back rather than take its account down with it.
    @Test("A stage stored before it carried an address is read as one that names none")
    func statusStoredWithoutPayloadIsRead() throws {
        let stored = Data(#"{"confirming":{}}"#.utf8)

        #expect(try JSONDecoder().decode(JointAccountStatus.self, from: stored) == .confirming(safeAddress: nil))
    }

    @Test("An unfinished operation rides inside its account through the listing")
    func operationIsRead() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.activeAccountsWithOperationJSON)

        let operation = try #require(response.jointAccounts.first?.operations?.first)

        #expect(operation.operationId == "0E2F4A6C-8D0B-4C5E-9F1A-2D4B6C8E0F2A")
        #expect(operation.chainId == 1)
        #expect(operation.status == .awaitingSignatures)
        #expect(operation.initiator == "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf")
        #expect(operation.threshold == 2)
        #expect(operation.createdAt == "2026-09-02T10:15:00Z")
        #expect(operation.safeTx.nonce == "7")
        #expect(operation.safeTx.operation == .call)
        #expect(operation.votes?.map(\.vote) == [.approve, .reject])
        // A refusal is not signed, so it comes back without one
        #expect(operation.votes?.map(\.signature) == ["0xfeed", nil])
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

    @Test("An operation is read into the domain with its Safe transaction typed")
    func operationIsMapped() throws {
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(Constants.activeAccountsWithOperationJSON)

        let account = try #require(try mapper.mapToJointAccounts(from: response).first)
        let operation = try #require(account.operations.first)

        #expect(operation.id == "0E2F4A6C-8D0B-4C5E-9F1A-2D4B6C8E0F2A")
        #expect(operation.chainId == 1)
        #expect(operation.status == .awaitingSignatures)
        #expect(operation.initiator == "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf")
        #expect(operation.safeTransaction.nonce == 7)
        #expect(operation.safeTransaction.baseGas == 118_000)
        #expect(operation.safeTransaction.gasPrice == 1_500_000_000)
        #expect(operation.safeTransaction.data.isEmpty)
        #expect(try SafeInnerCallTypeParser.parse(operation.safeTransaction.innerCall) == .transfer(.coin(destination: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c", value: 1_000_000_000_000_000)))
        #expect(operation.signatures.map(\.state) == [.signed, .declined])
    }

    @Test("An operation of a form this version cannot read keeps its place, with no call to show")
    func unreadableOperationKeepsItsPlace() throws {
        let json = Constants.activeAccountsWithOperationJSON.replacingOccurrences(of: "\"data\": \"0x\"", with: "\"data\": \"0x01\"")
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)

        let operation = try #require(try mapper.mapToJointAccounts(from: response).first?.operations.first)

        #expect(throws: SafeInnerCallTypeParser.Error.valueWithCalldata) {
            try SafeInnerCallTypeParser.parse(operation.safeTransaction.innerCall)
        }
    }

    @Test(
        "A figure that is not a number refuses the whole listing, the small ones like the big ones",
        arguments: [
            ("\"baseGas\": \"118000\"", "\"baseGas\": \"lots\"", "baseGas"),
            ("\"nonce\": \"7\"", "\"nonce\": \"seven\"", "nonce"),
            ("\"nonce\": \"7\"", "\"nonce\": \"-1\"", "nonce"),
        ]
    )
    func malformedOperationIsRefused(original: String, malformed: String, field: String) throws {
        let json = Constants.activeAccountsWithOperationJSON.replacingOccurrences(of: original, with: malformed)
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)

        #expect(throws: JointAccountsNetworkMapperError.malformedOperation(field: field)) {
            try mapper.mapToJointAccounts(from: response)
        }
    }

    @Test("The calldata a token transfer carries survives the reading byte for byte")
    func operationCallDataIsRead() throws {
        let callData = "a9059cbb0000000000000000000000002b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c00000000000000000000000000000000000000000000000000000000000f4240"
        let json = Constants.activeAccountsWithOperationJSON.replacingOccurrences(of: "\"data\": \"0x\"", with: "\"data\": \"0x\(callData)\"")
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)

        let account = try #require(try mapper.mapToJointAccounts(from: response).first)
        let operation = try #require(account.operations.first)

        #expect(operation.safeTransaction.data.hexString.lowercased() == callData)
    }

    @Test("Calldata that is not hex refuses the whole listing rather than passing for an empty one", arguments: ["0xnope", "0xa9059cb"])
    func malformedCallDataIsRefused(rawCallData: String) throws {
        let json = Constants.activeAccountsWithOperationJSON.replacingOccurrences(of: "\"data\": \"0x\"", with: "\"data\": \"\(rawCallData)\"")
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)

        #expect(throws: JointAccountsNetworkMapperError.malformedOperation(field: "data")) {
            try mapper.mapToJointAccounts(from: response)
        }
    }

    @Test("A stage this version has never heard of costs the operation its stage and nothing else")
    func unknownOperationStatusIsRead() throws {
        let json = Constants.activeAccountsWithOperationJSON.replacingOccurrences(of: "\"status\": \"awaiting_signatures\"", with: "\"status\": \"expired\"")
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)

        let account = try #require(try mapper.mapToJointAccounts(from: response).first)
        let operation = try #require(account.operations.first)

        #expect(operation.status == .unknown)
        #expect(operation.id == "0E2F4A6C-8D0B-4C5E-9F1A-2D4B6C8E0F2A")
    }

    @Test("A member's answer this version has never heard of costs that answer and nothing else")
    func unknownSignatureStateIsRead() throws {
        let json = Constants.activeAccountsWithOperationJSON.replacingOccurrences(
            of: "\"address\": \"0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c\", \"vote\": \"reject\"",
            with: "\"address\": \"0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c\", \"vote\": \"revoked\""
        )
        let response: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)

        let account = try #require(try mapper.mapToJointAccounts(from: response).first)
        let operation = try #require(account.operations.first)

        #expect(operation.status == .awaitingSignatures)
        #expect(operation.signatures.map(\.state) == [.signed, .unknown])
    }

    @Test("A stored operation stage survives a round trip, whether this version knows it or not")
    func operationStatusRoundTripsThroughStorage() throws {
        for status in [JointAccountOperationStatus.awaitingSignatures, .pending, .executed, .failed, .cancelled, .unknown] {
            let encoded = try JSONEncoder().encode([status])

            #expect(try JSONDecoder().decode([JointAccountOperationStatus].self, from: encoded) == [status])
        }
    }

    @Test("A kind of call the contract does not number refuses the whole listing")
    func unknownOperationKindIsRefused() {
        let json = Constants.activeAccountsWithOperationJSON.replacingOccurrences(of: "\"operation\": 0", with: "\"operation\": 2")

        #expect(throws: DecodingError.self) {
            let _: JointAccountsDTO.Response.JointAccounts = try Self.decode(json)
        }
    }

    @Test("A Safe transaction is written as the decimal strings the contract speaks in, the calldata lowercase")
    func safeTransactionIsWrittenTheWayTheContractSpeaks() throws {
        let dto = try mapper.mapToSafeTx(from: Self.makeSafeTransaction(data: Data([0xA9, 0x05, 0x9C, 0xBB])))

        #expect(dto.to == "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c")
        #expect(dto.value == "1000000000000000000")
        #expect(dto.data == "0xa9059cbb")
        #expect(dto.operation == .call)
        #expect(dto.safeTxGas == "23520")
        #expect(dto.baseGas == "100000")
        #expect(dto.gasPrice == "1575000000")
        #expect(dto.gasToken == "0x0000000000000000000000000000000000000000")
        #expect(dto.refundReceiver == "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf")
        #expect(dto.nonce == "7")
    }

    @Test("A plain transfer carries its empty calldata as a bare prefix, not as nothing")
    func emptyCalldataIsWrittenAsPrefix() throws {
        #expect(try mapper.mapToSafeTx(from: Self.makeSafeTransaction()).data == "0x")
    }

    @Test("A kind of call the contract does not number is refused rather than sent as a number")
    func unknownOperationKindIsNotWritten() {
        let safeTransaction = SafeTransaction(
            to: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
            value: 0,
            data: Data(),
            operation: 2,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: "0x0000000000000000000000000000000000000000",
            refundReceiver: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
            nonce: 0
        )

        #expect(throws: JointAccountsNetworkMapperError.malformedOperation(field: "operation")) {
            try mapper.mapToSafeTx(from: safeTransaction)
        }
    }

    @Test("Creating an operation names the Safe the signature's domain is built over")
    func createOperationRequestIsWritten() throws {
        let request = JointAccountOperationRequest(
            safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b",
            chainId: 1,
            safeTransaction: Self.makeSafeTransaction(),
            signature: Data([0x01, 0xAB, 0xFF])
        )

        let dto = try mapper.mapToRequest(from: request)

        #expect(dto.safeAddress == "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b")
        #expect(dto.chainId == 1)
        #expect(dto.safeTx.nonce == "7")
        #expect(dto.signature == "0x01ABFF")
    }

    /// The endpoint checks the signature against the body it is sent and the body against the one it holds, so one
    /// signature is not enough for it.
    @Test("Signing an operation sends the transaction along with the answer")
    func signOperationRequestIsWritten() throws {
        let dto = try mapper.mapToRequest(safeTransaction: Self.makeSafeTransaction(), signature: Data([0x01, 0xAB, 0xFF]))

        #expect(dto.safeTx.nonce == "7")
        #expect(dto.safeTx.operation == .call)
        #expect(dto.signature == "0x01ABFF")
    }
}

// MARK: - Helpers

private extension JointAccountsNetworkMapperTests {
    static func makeSafeTransaction(data: Data = Data()) -> SafeTransaction {
        SafeTransaction(
            to: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
            value: 1_000_000_000_000_000_000,
            data: data,
            operation: 0,
            safeTxGas: 23520,
            baseGas: 100_000,
            gasPrice: 1_575_000_000,
            gasToken: "0x0000000000000000000000000000000000000000",
            refundReceiver: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
            nonce: 7
        )
    }

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
                    "value": "1000000000000000",
                    "data": "0x",
                    "operation": 0,
                    "safeTxGas": "0",
                    "baseGas": "118000",
                    "gasPrice": "1500000000",
                    "gasToken": "0x0000000000000000000000000000000000000000",
                    "refundReceiver": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                    "nonce": "7"
                  },
                  "status": "awaiting_signatures",
                  "initiator": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                  "threshold": 2,
                  "votes": [
                    { "address": "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", "vote": "approve", "signature": "0xfeed", "votedAt": "2026-09-02T10:15:00Z" },
                    { "address": "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c", "vote": "reject", "signature": null, "votedAt": "2026-09-02T10:19:00Z" }
                  ],
                  "createdAt": "2026-09-02T10:15:00Z"
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
