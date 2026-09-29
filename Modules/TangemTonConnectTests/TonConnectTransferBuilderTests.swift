//
//  TonConnectTransferBuilderTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
import Foundation
import Testing
import TonSwift
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectTransferBuilderTests {
    private static let now = Date(timeIntervalSince1970: 1_764_424_242)
    private static var destination: Address { try! Address.parse("0:66fbe3c5c03bf5c82792f904c9f8bf28894a6aa3d213d41c20569b654aadedb3") }

    private func makeTransaction(validUntil: UInt64? = nil, messages: [TonConnectValidatedTransaction.Message]? = nil) -> TonConnectValidatedTransaction {
        TonConnectValidatedTransaction(
            validUntil: validUntil,
            messages: messages ?? [
                .init(destination: Self.destination, bounce: true, amount: BigUInt(100_000_000), payload: nil, stateInit: nil),
            ]
        )
    }

    @Test
    func derivesTheSameV4R2AddressAsBlockchainSdk() throws {
        // Vector from BlockchainSdkTests/TON/TONAddressTests (WalletCore derivation for the same key).
        let builder = try TonConnectTransferBuilder(publicKey: Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb"))

        #expect(try builder.address.toString(bounceable: false) == "UQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrdpr")
        #expect(try builder.address.toRaw() == "0:6aa21d29ab2eb3224b0664530b76a57943647baf39533b40eeaf3e8e9d480aad")
    }

    @Test
    func stateInitBocHashesToTheWalletAddress() throws {
        let builder = try TonConnectTransferBuilder(publicKey: Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb"))

        let boc = try builder.stateInitBoc()
        let cell = try Cell.fromBoc(src: Data(base64Encoded: boc)!)[0]

        #expect(cell.hash() == (try builder.address.hash), "spec: walletStateInit.hash() must equal address.hash()")
        // Public key is recoverable from the data cell: seqno(32) ++ wallet_id(32) ++ pubkey(256).
        let stateInitSlice = try cell.beginParse()
        #expect(try stateInitSlice.loadBit() == 0, "no split_depth")
        #expect(try stateInitSlice.loadBit() == 0, "no special")
        #expect(try stateInitSlice.loadMaybeRef() != nil, "code")
        let data = try #require(try stateInitSlice.loadMaybeRef()).beginParse()
        #expect(try data.loadUint(bits: 32) == 0)
        #expect(try data.loadUint(bits: 32) == 698_983_191)
        #expect(try data.loadBytes(32) == Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb"))
    }

    @Test
    func rejectsWrongPublicKeyLength() {
        #expect(throws: TonConnectError.self) {
            try TonConnectTransferBuilder(publicKey: Data(repeating: 1, count: 33))
        }
    }

    @Test
    func preparedHashIsHashOfV4SigningMessage() throws {
        let signer = FakeTonConnectSigner()
        let builder = try TonConnectTransferBuilder(publicKey: signer.publicKey, now: { Self.now })

        let prepared = try builder.prepare(makeTransaction(validUntil: 1_764_424_302), seqno: 7)

        #expect(prepared.hashToSign.count == 32)
        #expect(prepared.expiresAt == 1_764_424_302)

        let slice = try prepared.signingMessage.beginParse()
        #expect(try slice.loadUint(bits: 32) == 698_983_191, "wallet_id for workchain 0")
        #expect(try slice.loadUint(bits: 32) == 1_764_424_302, "valid_until")
        #expect(try slice.loadUint(bits: 32) == 7, "seqno")
        #expect(try slice.loadUint(bits: 8) == 0, "op: simple send")
        #expect(try slice.loadUint(bits: 8) == 3, "send mode PAY_GAS_SEPARATELY | IGNORE_ERRORS")
        #expect(slice.remainingRefs == 1)
    }

    @Test
    func expirationHonoursValidUntilButCapsAtWalletBound() throws {
        let builder = try TonConnectTransferBuilder(publicKey: FakeTonConnectSigner().publicKey, now: { Self.now })
        let cap = UInt64(Self.now.timeIntervalSince1970 + TonConnectTransferBuilder.defaultTimeout)

        #expect(try builder.prepare(makeTransaction(validUntil: nil), seqno: 1).expiresAt == cap)
        #expect(try builder.prepare(makeTransaction(validUntil: cap - 100), seqno: 1).expiresAt == cap - 100)
        #expect(try builder.prepare(makeTransaction(validUntil: cap + 100_000), seqno: 1).expiresAt == cap)
    }

    @Test
    func assembledExternalMessageCarriesVerifiableSignatureAndAllMessages() async throws {
        let signer = FakeTonConnectSigner()
        let builder = try TonConnectTransferBuilder(publicKey: signer.publicKey, now: { Self.now })
        let payloadCell = try Builder().store(uint: 0, bits: 32).writeSnakeString("comment").endCell()
        let transaction = makeTransaction(messages: [
            .init(destination: Self.destination, bounce: true, amount: BigUInt(100_000_000), payload: payloadCell, stateInit: nil),
            .init(destination: Self.destination, bounce: false, amount: BigUInt(1), payload: nil, stateInit: nil),
        ])

        let boc = try await builder.sign(transaction, seqno: 3, signer: signer)

        let external = try Message.loadFrom(slice: try Cell.fromBoc(src: Data(base64Encoded: boc)!)[0].beginParse())
        guard case .externalInInfo(let info) = external.info else {
            Issue.record("expected an ext_in_msg_info")
            return
        }
        #expect(info.dest == (try builder.address))
        #expect(external.stateInit == nil, "deployed wallet (seqno > 0) must not attach StateInit")

        let body = try external.body.beginParse()
        let signature = try body.loadBytes(64)
        let signingMessage = try body.loadRemainder()
        #expect(signer.verify(signature: signature, digest: signingMessage.hash()), "card signs the hash of the signing message")
        #expect(signer.signedDigests == [signingMessage.hash()])

        // Both outgoing messages are present, in order, with the requested bounce flags and bodies.
        let outgoing = try signingMessage.beginParse()
        _ = try outgoing.loadBits(32 + 32 + 32 + 8) // wallet_id, valid_until, seqno, op
        _ = try outgoing.loadUint(bits: 8) // send mode of message 1
        let first = try MessageRelaxed.loadFrom(slice: try outgoing.loadRef().beginParse())
        _ = try outgoing.loadUint(bits: 8) // send mode of message 2
        let second = try MessageRelaxed.loadFrom(slice: try outgoing.loadRef().beginParse())

        guard case .internalInfo(let firstInfo) = first.info, case .internalInfo(let secondInfo) = second.info else {
            Issue.record("expected internal messages")
            return
        }
        #expect(firstInfo.dest == Self.destination)
        #expect(firstInfo.bounce == true)
        #expect(firstInfo.value.coins.rawValue == BigUInt(100_000_000))
        #expect(first.body == payloadCell)
        #expect(secondInfo.bounce == false)
        #expect(secondInfo.value.coins.rawValue == BigUInt(1))
        #expect(second.body.bits.length == 0)
        #expect(second.body.refs.isEmpty)
    }

    @Test
    func attachesStateInitForUndeployedWalletAndForwardsMessageStateInit() async throws {
        let signer = FakeTonConnectSigner()
        let builder = try TonConnectTransferBuilder(publicKey: signer.publicKey, now: { Self.now })
        // StateInit with code and data refs, hand-built: split_depth=∅ special=∅ code=^ data=^ library=∅
        let destinationStateInit = try Builder()
            .store(bit: false)
            .store(bit: false)
            .store(bit: true).store(ref: Builder().store(uint: 1, bits: 8).endCell())
            .store(bit: true).store(ref: Builder().endCell())
            .store(bit: false)
            .endCell()
        let transaction = makeTransaction(messages: [
            .init(destination: Self.destination, bounce: false, amount: BigUInt(5), payload: nil, stateInit: destinationStateInit),
        ])

        let boc = try await builder.sign(transaction, seqno: 0, signer: signer)

        let external = try Message.loadFrom(slice: try Cell.fromBoc(src: Data(base64Encoded: boc)!)[0].beginParse())
        let walletStateInit = try #require(external.stateInit)
        #expect(try Builder().store(walletStateInit).endCell().hash() == (try builder.address.hash))

        let outgoing = try external.body.beginParse()
        _ = try outgoing.loadBytes(64)
        _ = try outgoing.loadBits(32 + 32 + 32 + 8 + 8)
        let message = try MessageRelaxed.loadFrom(slice: try outgoing.loadRef().beginParse())
        let forwarded = try #require(message.stateInit)
        #expect(try Builder().store(forwarded).endCell() == destinationStateInit)
    }

    @Test
    func assembleRejectsMalformedSignature() throws {
        let builder = try TonConnectTransferBuilder(publicKey: FakeTonConnectSigner().publicKey, now: { Self.now })
        let prepared = try builder.prepare(makeTransaction(), seqno: 1)

        #expect(throws: TonConnectError.self) {
            try builder.assemble(prepared, signature: Data(repeating: 0, count: 63))
        }
    }

    @Test
    func rejectsMoreThanFourMessages() throws {
        let builder = try TonConnectTransferBuilder(publicKey: FakeTonConnectSigner().publicKey, now: { Self.now })
        let message = TonConnectValidatedTransaction.Message(destination: Self.destination, bounce: true, amount: BigUInt(1), payload: nil, stateInit: nil)

        #expect(throws: (any Error).self) {
            try builder.prepare(makeTransaction(messages: Array(repeating: message, count: 5)), seqno: 1)
        }
    }
}
