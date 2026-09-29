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

        #expect(builder.address.toString(bounceable: false) == "UQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrdpr")
        #expect(builder.address.toRaw() == "0:6aa21d29ab2eb3224b0664530b76a57943647baf39533b40eeaf3e8e9d480aad")
    }

    @Test
    func stateInitBocHashesToTheWalletAddress() throws {
        let builder = try TonConnectTransferBuilder(publicKey: Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb"))

        let boc = try builder.stateInitBoc()
        let cell = try Cell.fromBoc(src: Data(base64Encoded: boc)!)[0]

        #expect(cell.hash() == builder.address.hash, "spec: walletStateInit.hash() must equal address.hash()")
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
        #expect(info.dest == builder.address)
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
        #expect(try Builder().store(walletStateInit).endCell().hash() == builder.address.hash)

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

    /// Vectors produced by the first implementation of this builder (TonSwift `MessageRelaxed`/`StateInit`
    /// types) before it was rewritten on raw `Builder` primitives; the Android module pins the same values.
    @Test
    func matchesPinnedCrossPlatformVectors() throws {
        let builder = try TonConnectTransferBuilder(publicKey: Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb"), now: { Self.now })
        let payload = TonConnectSendTransactionPayload(validUntil: 1_764_424_302, network: .mainnet, from: nil, messages: [
            .init(address: "EQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts90Q", amount: "100000000", payload: "te6cckEBAQEADQAAFgAAAABjb21tZW5053+evA=="),
            .init(address: "UQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts4DV", amount: "1"),
        ])
        let transaction = try TonConnectSendTransactionValidator(now: { Self.now })
            .validate(payload, for: TonConnectWalletAccount(address: builder.address, network: .mainnet))
        let signature = Data(repeating: 0x44, count: 64)

        // TonSwift's BoC writer orders cells by `Set` iteration, so the serialised bytes are not stable;
        // compare the cell tree instead.
        let pinnedStateInit = "te6cckECFgEAAwQAAgE0AgEAUQAAAAApqaMX5yh6gr3NOlwtDuIVDMvIDWoAmRQR+0TNTRPO9GYYqttAART/APSkE/S88sgLAwIBIAkEBPjygwjXGCDTH9Mf0x8C+CO78mTtRNDTH9Mf0//0BNFRQ7ryoVFRuvKiBfkBVBBk+RDyo/gAJKTIyx9SQMsfUjDL/1IQ9ADJ7VT4DwHTByHAAJ9sUZMg10qW0wfUAvsA6DDgIcAB4wAhwALjAAHAA5Ew4w0DpMjLHxLLH8v/CAcGBQAK9ADJ7VQAbIEBCNcY+gDTPzBSJIEBCPRZ8qeCEGRzdHJwdIAYyMsFywJQBc8WUAP6AhPLassfEss/yXP7AABwgQEI1xj6ANM/yFQgR4EBCPRR8qeCEG5vdGVwdIAYyMsFywJQBs8WUAT6AhTLahLLH8s/yXP7AAIAbtIH+gDU1CL5AAXIygcVy//J0Hd0gBjIywXLAiLPFlAF+gIUy2sSzMzJc/sAyEAUgQEI9FHypwICAUgTCgIBIAwLAFm9JCtvaiaECAoGuQ+gIYRw1AgIR6STfSmRDOaQPp/5g3gSgBt4EBSJhxWfMYQCASAODQARuMl+1E0NcLH4AgFYEg8CASAREAAZrx32omhAEGuQ64WPwAAZrc52omhAIGuQ64X/wAA9sp37UTQgQFA1yH0BDACyMoHy//J0AGBAQj0Cm+hMYALm0AHQ0wMhcbCSXwTgItdJwSCSXwTgAtMfIYIQcGx1Z70ighBkc3RyvbCSXwXgA/pAMCD6RAHIygfL/8nQ7UTQgQFA1yH0BDBcgQEI9ApvoTGzkl8H4AXTP8glghBwbHVnupI4MOMNA4IQZHN0crqSXwbjDRUUAIpQBIEBCPRZMO1E0IEBQNcgyAHPFvQAye1UAXKwjiOCEGRzdHKDHrFwgBhQBcsFUAPPFiP6AhPLassfyz/JgED7AJJfA+IAeAH6APQEMPgnbyIwUAqhIb7y4FCCEHBsdWeDHrFwgBhQBMsFJs8WWPoCGfQAy2kXyx9SYMs/IMmAQPsABtoNw/Q="
        #expect(try Cell.fromBoc(src: Data(base64Encoded: try builder.stateInitBoc())!)[0].hash() == Cell.fromBoc(src: Data(base64Encoded: pinnedStateInit)!)[0].hash())

        let deployed = try builder.prepare(transaction, seqno: 7)
        #expect(deployed.hashToSign == Data(hex: "5494af2299ac662eefb3e76f0ae6be3891d1afb2e5720777ab7086cb939fee48"))
        let pinnedDeployed = "te6cckECAwEAAOoAAuOIANVEOlNWXWZElgzIphbtSvKGyPdecqZ2gd1efR06kBVaAiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiFNTRi7SVfTcAAAADgAGBwCAQBiQgAzffHi4B365BPJfIJk/F+URKU1UekJ6g4QK02ypVb22YgIAAAAAAAAAAAAAAAAAAB+YgAzffHi4B365BPJfIJk/F+URKU1UekJ6g4QK02ypVb22aAvrwgAAAAAAAAAAAAAAAAAAAAAAABjb21tZW50c7QF8Q=="
        let deployedBoc = try builder.assemble(deployed, signature: signature)
        #expect(try Cell.fromBoc(src: Data(base64Encoded: deployedBoc)!)[0].hash() == Cell.fromBoc(src: Data(base64Encoded: pinnedDeployed)!)[0].hash())

        let undeployed = try builder.prepare(transaction, seqno: 0)
        #expect(undeployed.hashToSign == Data(hex: "39bcf1dd0c0b535aaa3e87fddbacdc94608657d33847dd19275eba79ef1aba65"))
        let undeployedBoc = try builder.assemble(undeployed, signature: signature)
        let undeployedRoot = try Cell.fromBoc(src: Data(base64Encoded: undeployedBoc)!)[0]
        #expect(undeployedRoot.refs.count == 4, "StateInit (2 refs) and both messages inline, as in the pinned vector")
        // 2+2+267+4 header, 1+1+5 inline StateInit, 1 body flag, 512 signature, 32+32+32+8 + 2×8 signing message = 915
        #expect(undeployedRoot.bits.length == 915)
        let pinnedUndeployed = "te6cckECGAEAA+wABOWIANVEOlNWXWZElgzIphbtSvKGyPdecqZ2gd1efR06kBVaEYiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiFNTRi7SVfTcAAAAAAAGBwAhYDAQBiQgAzffHi4B365BPJfIJk/F+URKU1UekJ6g4QK02ypVb22YgIAAAAAAAAAAAAAAAAAAEU/wD0pBP0vPLICwQAfmIAM33x4uAd+uQTyXyCZPxflESlNVHpCeoOECtNsqVW9tmgL68IAAAAAAAAAAAAAAAAAAAAAAAAY29tbWVudAIBIAkFBPjygwjXGCDTH9Mf0x8C+CO78mTtRNDTH9Mf0//0BNFRQ7ryoVFRuvKiBfkBVBBk+RDyo/gAJKTIyx9SQMsfUjDL/1IQ9ADJ7VT4DwHTByHAAJ9sUZMg10qW0wfUAvsA6DDgIcAB4wAhwALjAAHAA5Ew4w0DpMjLHxLLH8v/DggHBgAK9ADJ7VQAbIEBCNcY+gDTPzBSJIEBCPRZ8qeCEGRzdHJwdIAYyMsFywJQBc8WUAP6AhPLassfEss/yXP7AABwgQEI1xj6ANM/yFQgR4EBCPRR8qeCEG5vdGVwdIAYyMsFywJQBs8WUAT6AhTLahLLH8s/yXP7AAICAUgMCgIBIA8LAFm9JCtvaiaECAoGuQ+gIYRw1AgIR6STfSmRDOaQPp/5g3gSgBt4EBSJhxWfMYQC5tAB0NMDIXGwkl8E4CLXScEgkl8E4ALTHyGCEHBsdWe9IoIQZHN0cr2wkl8F4AP6QDAg+kQByMoHy//J0O1E0IEBQNch9AQwXIEBCPQKb6Exs5JfB+AF0z/IJYIQcGx1Z7qSODDjDQOCEGRzdHK6kl8G4w0XDQCKUASBAQj0WTDtRNCBAUDXIMgBzxb0AMntVAFysI4jghBkc3Rygx6xcIAYUAXLBVADzxYj+gITy2rLH8s/yYBA+wCSXwPiAG7SB/oA1NQi+QAFyMoHFcv/ydB3dIAYyMsFywIizxZQBfoCFMtrEszMyXP7AMhAFIEBCPRR8qcCAgEgERAAEbjJftRNDXCx+AIBWBUSAgEgFBMAGa8d9qJoQBBrkOuFj8AAGa3OdqJoQCBrkOuF/8AAPbKd+1E0IEBQNch9AQwAsjKB8v/ydABgQEI9ApvoTGAAUQAAAAApqaMX5yh6gr3NOlwtDuIVDMvIDWoAmRQR+0TNTRPO9GYYqttAAHgB+gD0BDD4J28iMFAKoSG+8uBQghBwbHVngx6xcIAYUATLBSbPFlj6Ahn0AMtpF8sfUmDLPyDJgED7AAZRXkSf"
        #expect(try undeployedRoot.hash() == Cell.fromBoc(src: Data(base64Encoded: pinnedUndeployed)!)[0].hash())
    }

    @Test
    func forwardableStateInitCheckAcceptsEmptyLibraryOnly() throws {
        let code = try Builder().store(uint: 1, bits: 8).endCell()
        let plain = try Builder().store(bit: false).store(bit: false).store(bit: true).store(ref: code).store(bit: true).store(ref: Builder().endCell()).store(bit: false).endCell()
        let withLibrary = try Builder().store(bit: false).store(bit: false).store(bit: false).store(bit: false).store(bit: true).store(ref: code).endCell()
        let missingRef = try Builder().store(bit: false).store(bit: false).store(bit: true).store(bit: false).store(bit: false).endCell()
        let trailingBits = try Builder().store(bit: false).store(bit: false).store(bit: false).store(bit: false).store(bit: false).store(bit: true).endCell()

        #expect(TonConnectTransferBuilder.isForwardableStateInit(plain))
        #expect(!TonConnectTransferBuilder.isForwardableStateInit(withLibrary), "non-empty HashmapE is refused, never parsed")
        #expect(!TonConnectTransferBuilder.isForwardableStateInit(missingRef))
        #expect(!TonConnectTransferBuilder.isForwardableStateInit(trailingBits))
    }
}
