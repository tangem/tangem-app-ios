//
//  WalletConnectTronRequestParserTests.swift
//  TangemTests
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemSdk
import struct Commons.AnyCodable
@testable import Tangem

/// Protobuf vectors are hand-encoded `protocol.Transaction.raw` messages (ref block 7803/16138f9255a1db91,
/// expiration 1756201572000, timestamp 1756201512720); txIDs are their sha256. The contract-call vector reproduces
/// the `TriggerSmartContract` example from the Reown Tron RPC reference.
struct WalletConnectTronRequestParserTests {
    private enum Vectors {
        static let owner = "TKZRPqoV7WLFvjhT4cEyBLv27Rvv1RNWGj"
        static let recipient = "TCaucrAr4itZrmpjK1Pg4CVS7bym2QiFG4"
        static let usdtContract = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"

        /// TransferContract owner → recipient, 1.5 TRX, memo "hi".
        static let transferRaw = "0a027803220816138f9255a1db9140a0ad95ae8e33520268695a67080112630a2d747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e5472616e73666572436f6e747261637412320a154169319ea845b1c35a1f7b0e1429f4f303e8f791331215411cb0b7348eded93b8d0816bbeb819fc1d7a51f3118e0c65b7090de91ae8e33"
        static let transferTxID = "c29f0e70467cf63193df2a66fbd26b618e4227fcd9805d4dbf77bef3bb255b7c"

        /// TriggerSmartContract owner → USDT `approve(recipient, 0)`, fee_limit 200 TRX.
        static let callRaw = "0a027803220816138f9255a1db9140a0ad95ae8e335aae01081f12a9010a31747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412740a154169319ea845b1c35a1f7b0e1429f4f303e8f79133121541a614f803b6fd780986a42c78ec9c7f77e6ded13c2244095ea7b30000000000000000000000001cb0b7348eded93b8d0816bbeb819fc1d7a51f3100000000000000000000000000000000000000000000000000000000000000007090de91ae8e3390018084af5f"
        static let callTxID = "96508271130eb1790770b5a5661f5604b96db5a1e9c456eb1e58856e1724e0e3"
        static let callData = "095ea7b30000000000000000000000001cb0b7348eded93b8d0816bbeb819fc1d7a51f310000000000000000000000000000000000000000000000000000000000000000"

        /// TransferContract whose owner is `recipient`, not the connected account.
        static let foreignOwnerRaw = "0a027803220816138f9255a1db9140a0ad95ae8e335a65080112610a2d747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e5472616e73666572436f6e747261637412300a15411cb0b7348eded93b8d0816bbeb819fc1d7a51f3112154169319ea845b1c35a1f7b0e1429f4f303e8f7913318017090de91ae8e33"

        /// FreezeBalanceV2Contract — not a transfer or a call.
        static let freezeRaw = "0a027803220816138f9255a1db9140a0ad95ae8e335a530836124f0a34747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e467265657a6542616c616e63655632436f6e747261637412170a154169319ea845b1c35a1f7b0e1429f4f303e8f791337090de91ae8e33"
    }

    private func unsigned(rawDataHex: String, txID: String? = nil) -> WalletConnectTronSignTransactionDTO.UnsignedTransaction {
        let json = """
        {"raw_data_hex":"\(rawDataHex)"\(txID.map { ",\"txID\":\"\($0)\"" } ?? ""),"visible":false,"raw_data":{"contract":[]}}
        """
        return try! JSONDecoder().decode(WalletConnectTronSignTransactionDTO.UnsignedTransaction.self, from: Data(json.utf8))
    }

    // MARK: - Transfer

    @Test
    func parsesTransferAndDerivesTxIDFromRawData() throws {
        let signable = try WalletConnectTronRequestParser.makeSignableTransaction(
            from: unsigned(rawDataHex: Vectors.transferRaw, txID: Vectors.transferTxID),
            expectedOwnerAddress: Vectors.owner
        )

        #expect(signable.hash.hexString.lowercased() == Vectors.transferTxID)
        #expect(signable.rawData == Data(hexString: Vectors.transferRaw))
        #expect(signable.parsed == .init(
            kind: .transfer,
            ownerAddress: Vectors.owner,
            targetAddress: Vectors.recipient,
            amountSun: 1_500_000,
            callData: nil,
            feeLimitSun: nil,
            memo: "hi",
            txID: Vectors.transferTxID
        ))
    }

    @Test
    func parsesContractCallWithFeeLimitAndCalldata() throws {
        let signable = try WalletConnectTronRequestParser.makeSignableTransaction(
            from: unsigned(rawDataHex: "0x" + Vectors.callRaw),
            expectedOwnerAddress: Vectors.owner
        )

        #expect(signable.parsed.kind == .contractCall)
        #expect(signable.parsed.ownerAddress == Vectors.owner)
        #expect(signable.parsed.targetAddress == Vectors.usdtContract)
        #expect(signable.parsed.amountSun == 0)
        #expect(signable.parsed.callData == Vectors.callData)
        #expect(signable.parsed.feeLimitSun == 200_000_000)
        #expect(signable.parsed.memo == nil)
        #expect(signable.parsed.txID == Vectors.callTxID)
    }

    // MARK: - Rejections

    @Test
    func rejectsTxIDThatDoesNotMatchRawData() {
        #expect(throws: WalletConnectTronRequestError.txIDMismatch) {
            try WalletConnectTronRequestParser.makeSignableTransaction(
                from: unsigned(rawDataHex: Vectors.transferRaw, txID: Vectors.callTxID),
                expectedOwnerAddress: Vectors.owner
            )
        }
    }

    @Test
    func rejectsTransactionOwnedByAnotherAccount() {
        #expect(throws: WalletConnectTronRequestError.ownerMismatch) {
            try WalletConnectTronRequestParser.makeSignableTransaction(
                from: unsigned(rawDataHex: Vectors.foreignOwnerRaw),
                expectedOwnerAddress: Vectors.owner
            )
        }
        // Same bytes, but the owner of the transfer is the connected account: accepted.
        #expect(throws: Never.self) {
            try WalletConnectTronRequestParser.makeSignableTransaction(
                from: unsigned(rawDataHex: Vectors.foreignOwnerRaw),
                expectedOwnerAddress: Vectors.recipient
            )
        }
    }

    @Test
    func rejectsUnsupportedContractTypesAndMalformedBytes() {
        #expect(throws: WalletConnectTronRequestError.unsupportedTransaction("unsupportedContractType")) {
            try WalletConnectTronRequestParser.makeSignableTransaction(from: unsigned(rawDataHex: Vectors.freezeRaw), expectedOwnerAddress: Vectors.owner)
        }
        #expect(throws: WalletConnectTronRequestError.invalidRawData) {
            try WalletConnectTronRequestParser.makeSignableTransaction(from: unsigned(rawDataHex: ""), expectedOwnerAddress: Vectors.owner)
        }
        #expect(throws: WalletConnectTronRequestError.invalidRawData) {
            try WalletConnectTronRequestParser.makeSignableTransaction(from: unsigned(rawDataHex: "zz"), expectedOwnerAddress: Vectors.owner)
        }
        #expect(throws: WalletConnectTronRequestError.unsupportedTransaction("invalidRawTransaction")) {
            try WalletConnectTronRequestParser.makeSignableTransaction(from: unsigned(rawDataHex: "0a02"), expectedOwnerAddress: Vectors.owner)
        }
        #expect(throws: WalletConnectTronRequestError.invalidRawData) {
            try WalletConnectTronRequestParser.makeSignableTransaction(
                from: unsigned(rawDataHex: String(repeating: "00", count: WalletConnectTronRequestParser.maxRawDataByteCount + 1)),
                expectedOwnerAddress: Vectors.owner
            )
        }
    }

    // MARK: - Request layouts

    @Test
    func decodesLegacyNestedAndV1RequestLayouts() throws {
        let v1 = """
        {"address":"\(Vectors.owner)","transaction":{"visible":false,"txID":"\(Vectors.callTxID)","raw_data":{"contract":[]},"raw_data_hex":"\(Vectors.callRaw)"}}
        """
        let legacy = """
        {"address":"\(Vectors.owner)","transaction":{"transaction":{"raw_data":{"contract":[]},"raw_data_hex":"\(Vectors.callRaw)"}}}
        """

        let v1Request = try JSONDecoder().decode(WalletConnectTronSignTransactionDTO.Request.self, from: Data(v1.utf8))
        let legacyRequest = try JSONDecoder().decode(WalletConnectTronSignTransactionDTO.Request.self, from: Data(legacy.utf8))

        #expect(v1Request.unsignedTransaction.rawDataHex == Vectors.callRaw)
        #expect(v1Request.unsignedTransaction.txID == Vectors.callTxID)
        #expect(legacyRequest.unsignedTransaction.rawDataHex == Vectors.callRaw)
        #expect(legacyRequest.unsignedTransaction.txID == nil)
        #expect(legacyRequest.address == Vectors.owner)
    }

    @Test
    func responseEchoesRawDataAndCarriesSignatureArray() throws {
        let rawData = try AnyCodable(any: JSONSerialization.jsonObject(with: Data(#"{"contract":[{"type":"TransferContract"}],"fee_limit":1}"#.utf8)))
        let response = WalletConnectTronSignTransactionDTO.Response(
            txID: Vectors.transferTxID,
            signature: ["aa"],
            rawData: rawData,
            rawDataHex: Vectors.transferRaw,
            visible: true
        )

        let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(response)) as? [String: Any])

        #expect(object["txID"] as? String == Vectors.transferTxID)
        #expect(object["signature"] as? [String] == ["aa"])
        #expect(object["raw_data_hex"] as? String == Vectors.transferRaw)
        #expect(object["visible"] as? Bool == true)
        #expect((object["raw_data"] as? [String: Any])?["fee_limit"] as? Int == 1)
    }

    // MARK: - Message signing

    @Test
    func messageDigestFollowsSignMessageV2Layout() {
        // keccak256("\x19TRON Signed Message:\n" ‖ "39" ‖ message), computed with a reference Keccak.
        #expect(WalletConnectTronRequestParser.messageDigest("This is a message to be signed for Tron").hexString.lowercased()
            == "aa8faa6427ddbbcbcdd441df0adec9ddebc1188e0d4cce7a43a3d4bf9496acac")
        // Length prefix counts UTF-8 bytes (12), not characters (6).
        #expect(WalletConnectTronRequestParser.messageDigest("Привет").hexString.lowercased()
            == "86914ed657b597fe28295a8b16336b018243e570a49091fae83f22f71c800e4a")
    }

    @Test
    func signatureFormattingRebasesRecoveryByteForTransactionsOnly() throws {
        let rs = Data(repeating: 0xAB, count: 64)

        #expect(try WalletConnectTronRequestParser.transactionSignatureHex(from: rs + Data([27])) == rs.hexString.lowercased() + "00")
        #expect(try WalletConnectTronRequestParser.transactionSignatureHex(from: rs + Data([28])) == rs.hexString.lowercased() + "01")
        #expect(try WalletConnectTronRequestParser.messageSignatureHex(from: rs + Data([28])) == "0x" + rs.hexString.lowercased() + "1c")

        #expect(throws: WCTransactionSignError.self) { try WalletConnectTronRequestParser.transactionSignatureHex(from: rs) }
        #expect(throws: WCTransactionSignError.self) { try WalletConnectTronRequestParser.transactionSignatureHex(from: rs + Data([1])) }
    }

    // MARK: - Request details

    @Test
    func detailsModelRendersTransferAndCallFromParsedTransaction() throws {
        let transfer = try WalletConnectTronRequestParser.makeSignableTransaction(from: unsigned(rawDataHex: Vectors.transferRaw), expectedOwnerAddress: Vectors.owner).parsed
        let call = try WalletConnectTronRequestParser.makeSignableTransaction(from: unsigned(rawDataHex: Vectors.callRaw), expectedOwnerAddress: Vectors.owner).parsed

        let transferSections = WCTronSignTransactionDetailsModel(for: .tronSignTransaction, source: try JSONEncoder().encode(transfer)).data
        let callSections = WCTronSignTransactionDetailsModel(for: .tronSignTransaction, source: try JSONEncoder().encode(call)).data

        let transferItems = transferSections.flatMap(\.items).map { ($0.title, $0.value) }
        #expect(transferItems.contains { $0 == ("Contract", "TransferContract") })
        #expect(transferItems.contains { $0 == ("To", Vectors.recipient) })
        #expect(transferItems.contains { $0 == ("Amount", "1.5 TRX") })
        #expect(transferItems.contains { $0 == ("Memo", "hi") })

        let callItems = callSections.flatMap(\.items).map { ($0.title, $0.value) }
        #expect(callItems.contains { $0 == ("Contract", "TriggerSmartContract") })
        #expect(callItems.contains { $0 == ("Contract address", Vectors.usdtContract) })
        #expect(callItems.contains { $0 == ("Data", "0x" + Vectors.callData) })
        #expect(callItems.contains { $0 == ("Fee limit", "200 TRX") })
        #expect(WCTronSignTransactionDetailsModel(for: .tronSignTransaction, source: Data("nope".utf8)).data.isEmpty)
    }

    @Test
    func chainIDsAndMethodsAreRegistered() {
        #expect(BlockchainSdk.Blockchain.tron(testnet: false).wcChainID == ["0x2b6653dc"])
        #expect(BlockchainSdk.Blockchain.tron(testnet: true).wcChainID == ["0xcd8690dc", "0x94a9059e"])
        #expect(WalletConnectMethod(rawValue: "tron_signTransaction") == .tronSignTransaction)
        #expect(WalletConnectMethod(rawValue: "tron_signMessage") == .tronSignMessage)
        #expect(WalletConnectSupportedNamespace(rawValue: "tron") == .tron)
    }
}
