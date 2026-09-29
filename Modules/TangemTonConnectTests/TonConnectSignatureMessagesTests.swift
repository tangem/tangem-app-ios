//
//  TonConnectSignatureMessagesTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import Testing
import TonSwift
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectSignatureMessagesTests {
    private static var address: Address { try! Address.parse("0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae") }
    private static let domain = "ton-connect.github.io"
    private static let timestamp: UInt64 = 1_764_424_242

    // MARK: - ton_proof

    @Test
    func proofMessageFollowsSpecLayout() {
        let message = TonConnectProofMessage.message(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, payload: "nonce")

        var expected = Data("ton-proof-item-v2/".utf8)
        expected += Data([0x00, 0x00, 0x00, 0x00]) // workchain 0, int32 big-endian
        expected += Self.address.hash
        expected += Data([0x15, 0x00, 0x00, 0x00]) // 21 = len("ton-connect.github.io"), uint32 little-endian
        expected += Data(Self.domain.utf8)
        expected += Data([0x32, 0xFA, 0x2A, 0x69, 0x00, 0x00, 0x00, 0x00]) // 1764424242, uint64 little-endian
        expected += Data("nonce".utf8)

        #expect(message == expected)
    }

    @Test
    func proofMessageEncodesMasterchainWorkchainAsNegativeBigEndian() {
        let masterchain = Address(workchain: -1, hash: Data(repeating: 0x11, count: 32))
        let message = TonConnectProofMessage.message(address: masterchain, appDomain: "a.b", timestamp: 0, payload: "")

        let workchainBytes = message.dropFirst("ton-proof-item-v2/".utf8.count).prefix(4)
        #expect(Array(workchainBytes) == [0xFF, 0xFF, 0xFF, 0xFF])
    }

    @Test
    func proofDigestIsDoubleHashWithTonConnectPrefix() {
        let message = TonConnectProofMessage.message(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, payload: "p")
        let inner = Data(SHA256.hash(data: message))
        let expected = Data(SHA256.hash(data: Data([0xFF, 0xFF]) + Data("ton-connect".utf8) + inner))

        #expect(TonConnectProofMessage.digest(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, payload: "p") == expected)
    }

    @Test
    func makeProofSignsDigestAndPackagesReply() async throws {
        let signer = FakeTonConnectSigner()

        let proof = try await TonConnectProofMessage.makeProof(address: Self.address, appDomain: Self.domain, payload: "nonce", timestamp: Self.timestamp, signer: signer)

        let digest = TonConnectProofMessage.digest(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, payload: "nonce")
        #expect(signer.signedDigests == [digest])
        #expect(proof.timestamp == "1764424242")
        #expect(proof.domain.value == Self.domain)
        #expect(proof.domain.lengthBytes == 21)
        #expect(proof.payload == "nonce")
        let signature = try #require(Data(base64Encoded: proof.signature))
        #expect(signer.verify(signature: signature, digest: digest))
    }

    @Test
    func makeProofRejectsMalformedSignature() async {
        await #expect(throws: TonConnectError.self) {
            _ = try await TonConnectProofMessage.makeProof(address: Self.address, appDomain: Self.domain, payload: "n", timestamp: 1, signer: BrokenTonConnectSigner())
        }
    }

    // MARK: - signData text / binary (big-endian, matches the reference verifier)

    @Test
    func signDataTextMessageFollowsReferenceLayout() throws {
        let message = try TonConnectSignDataMessage.flatMessage(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, content: .text("Hi"))

        var expected = Data([0xFF, 0xFF]) + Data("ton-connect/sign-data/".utf8)
        expected += Data([0, 0, 0, 0]) + Self.address.hash
        expected += Data([0x00, 0x00, 0x00, 0x15]) + Data(Self.domain.utf8) // uint32 big-endian
        expected += Data([0x00, 0x00, 0x00, 0x00, 0x69, 0x2A, 0xFA, 0x32]) // uint64 big-endian
        expected += Data("txt".utf8) + Data([0x00, 0x00, 0x00, 0x02]) + Data("Hi".utf8)

        #expect(message == expected)
    }

    @Test
    func signDataBinaryMessageUsesBinPrefixAndRawBytes() throws {
        let bytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let message = try TonConnectSignDataMessage.flatMessage(address: Self.address, appDomain: Self.domain, timestamp: 0, content: .binary(bytes))

        #expect(message.suffix(4 + 4 + 3) == Data("bin".utf8) + Data([0, 0, 0, 4]) + bytes)
    }

    @Test
    func signDataTextDigestIsSHA256OfMessage() throws {
        let payload = TonConnectSignDataPayload(content: .text("Sign in"), network: .mainnet, from: nil)
        let message = try TonConnectSignDataMessage.flatMessage(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, content: payload.content)

        let digest = try TonConnectSignDataMessage.digest(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, payload: payload)

        #expect(digest == Data(SHA256.hash(data: message)))
    }

    // MARK: - signData cell

    @Test
    func dnsWireFormatReversesLabelsWithNulTerminators() {
        #expect(TonConnectSignDataMessage.dnsWireFormat(of: "ton-connect.github.io") == Data("io\0github\0ton-connect\0".utf8))
        #expect(TonConnectSignDataMessage.dnsWireFormat(of: "stonfi.com") == Data("com\0stonfi\0".utf8))
    }

    @Test
    func crc32MatchesIEEEReferenceValues() {
        #expect(CRC32.checksum(Data("123456789".utf8)) == 0xCBF4_3926)
        #expect(CRC32.checksum(Data()) == 0)
        #expect(CRC32.checksum(Data("The quick brown fox jumps over the lazy dog".utf8)) == 0x414F_A339)
    }

    @Test
    func signDataCellMessageHasSpecStructure() throws {
        let schema = "message#1234 value:uint32 = Message;"
        let payloadCell = try Builder().store(uint: 42, bits: 32).endCell()

        let cell = try TonConnectSignDataMessage.cellMessage(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, schema: schema, payload: payloadCell)

        let slice = try cell.beginParse()
        #expect(try slice.loadUint(bits: 32) == UInt64(TonConnectSignDataMessage.cellMagic))
        #expect(try slice.loadUint(bits: 32) == UInt64(CRC32.checksum(Data(schema.utf8))))
        #expect(try slice.loadUint(bits: 64) == Self.timestamp)
        #expect(try Address.loadFrom(slice: slice) == Self.address)
        let domainCell = try slice.loadRef()
        #expect(try domainCell.beginParse().loadSnakeData() == Data("io\0github\0ton-connect\0".utf8))
        #expect(try slice.loadRef() == payloadCell)
        #expect(slice.remainingBits == 0)
        #expect(slice.remainingRefs == 0)
    }

    @Test
    func signDataCellDigestIsCellHash() throws {
        let payloadCell = try Builder().store(uint: 7, bits: 8).endCell()
        let boc = try TonConnectBoc.base64(payloadCell)
        let payload = TonConnectSignDataPayload(content: .cell(schema: "x#00 = X;", cellBoc: boc), network: nil, from: nil)

        let digest = try TonConnectSignDataMessage.digest(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, payload: payload)
        let expected = try TonConnectSignDataMessage.cellMessage(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, schema: "x#00 = X;", payload: payloadCell).hash()

        #expect(digest == expected)
        #expect(digest.count == 32)
    }

    @Test
    func signDataRejectsMalformedCellBoc() {
        let payload = TonConnectSignDataPayload(content: .cell(schema: "x", cellBoc: "not-a-boc"), network: nil, from: nil)

        #expect(throws: TonConnectError.self) {
            try TonConnectSignDataMessage.digest(address: Self.address, appDomain: Self.domain, timestamp: 0, payload: payload)
        }
    }

    @Test
    func signProducesVerifiableResultEchoingPayload() async throws {
        let signer = FakeTonConnectSigner()
        let payload = TonConnectSignDataPayload(content: .text("Confirm"), network: .mainnet, from: "UQCKhieGGl3ZbJ2zzggHsSLaXtRzk0znVopbSxw2HLsorroM")

        let result = try await TonConnectSignDataMessage.sign(payload: payload, address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, signer: signer)

        #expect(result.address == "0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae")
        #expect(result.timestamp == Self.timestamp)
        #expect(result.domain == Self.domain)
        #expect(result.payload == payload)
        let digest = try TonConnectSignDataMessage.digest(address: Self.address, appDomain: Self.domain, timestamp: Self.timestamp, payload: payload)
        #expect(signer.verify(signature: Data(base64Encoded: result.signature)!, digest: digest))
    }
}
