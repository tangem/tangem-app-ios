//
//  TonConnectHardeningTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TonSwift
@testable import TangemTonConnect

/// Rules added after the security pass over the module: every dApp- or bridge-controlled input that could
/// steer a signature to the wrong network/account, launch an arbitrary URL, or grow memory without bound.
@Suite(.tags(.tonConnect))
struct TonConnectHardeningTests {
    private static var wallet: Address { try! Address.parse("0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae") }
    private static var other: Address { try! Address.parse("0:66fbe3c5c03bf5c82792f904c9f8bf28894a6aa3d213d41c20569b654aadedb3") }
    private static var mainnetAccount: TonConnectWalletAccount { TonConnectWalletAccount(address: wallet, network: .mainnet) }

    // MARK: - signData validator

    @Test
    func signDataValidatorAcceptsMatchingNetworkAndAccount() throws {
        let validator = TonConnectSignDataValidator()
        let payload = TonConnectSignDataPayload(content: .text("Sign in"), network: .mainnet, from: Self.wallet.toString(bounceable: false))

        #expect(throws: Never.self) {
            try validator.validate(payload, for: Self.mainnetAccount, supportedTypes: [.text, .binary, .cell])
        }
        #expect(throws: Never.self) {
            try validator.validate(TonConnectSignDataPayload(content: .binary(Data([1])), network: nil, from: nil), for: Self.mainnetAccount, supportedTypes: [.binary])
        }
    }

    @Test
    func signDataValidatorRejectsForeignNetworkAccountTypeAndOversizedPayloads() throws {
        let validator = TonConnectSignDataValidator()
        let all: Set<TonConnectSignDataType> = [.text, .binary, .cell]

        #expect(throws: TonConnectError.badRequest("network -3 does not match the connected account network -239")) {
            try validator.validate(TonConnectSignDataPayload(content: .text("x"), network: .testnet, from: nil), for: Self.mainnetAccount, supportedTypes: all)
        }
        #expect(throws: TonConnectError.badRequest("from does not match the connected account")) {
            try validator.validate(TonConnectSignDataPayload(content: .text("x"), network: nil, from: Self.other.toRaw()), for: Self.mainnetAccount, supportedTypes: all)
        }
        #expect(throws: TonConnectError.badRequest("from is not a valid TON address")) {
            try validator.validate(TonConnectSignDataPayload(content: .text("x"), network: nil, from: "nope"), for: Self.mainnetAccount, supportedTypes: all)
        }
        #expect(throws: TonConnectError.badRequest("signData type cell is not supported by this wallet")) {
            try validator.validate(TonConnectSignDataPayload(content: .cell(schema: "x", cellBoc: "te6ccgEBAQEAAgAAAA=="), network: nil, from: nil), for: Self.mainnetAccount, supportedTypes: [.text])
        }
        #expect(throws: TonConnectError.badRequest("text payload exceeds \(TonConnectSignDataValidator.maxPayloadByteCount) bytes")) {
            try validator.validate(TonConnectSignDataPayload(content: .text(String(repeating: "a", count: TonConnectSignDataValidator.maxPayloadByteCount + 1)), network: nil, from: nil), for: Self.mainnetAccount, supportedTypes: all)
        }
        #expect(throws: TonConnectError.self) {
            try validator.validate(TonConnectSignDataPayload(content: .cell(schema: "x", cellBoc: "not-a-boc"), network: nil, from: nil), for: Self.mainnetAccount, supportedTypes: all)
        }
    }

    // MARK: - Connect: requested network

    @Test
    func connectFactoryRefusesMismatchedRequestedNetwork() async throws {
        let signer = FakeTonConnectSigner()
        let factory = TonConnectConnectEventFactory(deviceInfo: TonConnectDeviceInfo(platform: .iphone, appName: "tangem", appVersion: "1", features: []))
        let request = TonConnectConnectRequest(manifestUrl: URL(string: "https://a.b/m.json")!, items: [.tonAddress(network: .testnet)])

        await #expect(throws: TonConnectError.badRequest("requested network -3 does not match the wallet network -239")) {
            _ = try await factory.makeApproval(request: request, publicKey: signer.publicKey, network: .mainnet, appDomain: "a.b", eventID: 0, signer: signer)
        }
        #expect(signer.signedDigests.isEmpty)
    }

    // MARK: - sendTransaction: test-only destinations

    @Test
    func sendTransactionRejectsTestOnlyDestinationOnMainnet() throws {
        let validator = TonConnectSendTransactionValidator(now: { Date(timeIntervalSince1970: 1_764_424_242) })
        let testOnly = Self.other.toString(testOnly: true, bounceable: true)
        let payload = TonConnectSendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: [.init(address: testOnly, amount: "1")])

        #expect(throws: TonConnectError.badRequest("messages[0].address is a test-only address, the connected account is on mainnet")) {
            try validator.validate(payload, for: Self.mainnetAccount)
        }
        #expect(throws: Never.self) {
            try validator.validate(payload, for: TonConnectWalletAccount(address: Self.wallet, network: .testnet))
        }
    }

    @Test
    func sendTransactionRejectsStateInitWithLibraryDictionaryWithoutParsingIt() throws {
        let validator = TonConnectSendTransactionValidator(now: { Date(timeIntervalSince1970: 1_764_424_242) })
        // library:(HashmapE 256 SimpleLib) present, with a label whose length exceeds the key — the input that
        // makes TonSwift's `StateInit.loadFrom` trap in `bitsForInt`.
        let hostileLabel = try Builder().store(bit: true).store(bit: false).store(uint: 511, bits: 9).store(bit: 1, repeat: 511).endCell()
        let stateInit = try Builder().store(bit: false).store(bit: false).store(bit: false).store(bit: false).store(bit: true).store(ref: hostileLabel).endCell()
        let payload = TonConnectSendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: [
            .init(address: Self.other.toString(bounceable: true), amount: "1", stateInit: try TonConnectBoc.base64(stateInit)),
        ])

        #expect(throws: TonConnectError.badRequest("messages[0].stateInit is not a valid StateInit cell")) {
            try validator.validate(payload, for: Self.mainnetAccount)
        }
    }

    // MARK: - Deep link: return targets

    @Test
    func returnStrategyOnlyOpensWebAndTelegramURLs() throws {
        let parser = TonConnectDeepLinkParser()
        let id = String(repeating: "ab", count: 32)
        func ret(_ value: String) throws -> TonConnectDeepLink.ReturnStrategy {
            var components = URLComponents(string: "tc://")!
            components.queryItems = [URLQueryItem(name: "id", value: id), URLQueryItem(name: "ret", value: value)]
            return try parser.parse(components.url!).returnStrategy
        }

        #expect(try ret("https://dapp.example/done") == .url(URL(string: "https://dapp.example/done")!))
        #expect(try ret("tg://resolve?domain=dapp") == .url(URL(string: "tg://resolve?domain=dapp")!))
        #expect(try ret("tel:+123456") == .back)
        #expect(try ret("sms:123") == .back)
        #expect(try ret("tonkeeper://transfer/x") == .back)
        #expect(try ret("file:///etc/passwd") == .back)
    }

    // MARK: - SSE: memory bound

    @Test
    func sseParserDropsEventsLargerThanTheCap() {
        var parser = TonConnectSSEParser()
        let chunk = String(repeating: "x", count: 256 * 1024)

        for _ in 0 ..< 5 { // 5 × 256 KiB > 1 MiB
            #expect(parser.feed(line: "data: " + chunk) == nil)
        }
        #expect(parser.feed(line: "") == nil, "oversized event is dropped, not delivered truncated")

        // The parser is usable again for the next event.
        #expect(parser.feed(line: "data: ok") == nil)
        #expect(parser.feed(line: "") == TonConnectSSEEvent(id: nil, event: nil, data: "ok"))
    }

    // MARK: - Manifest: size, serving host, IP literals

    @Test
    func manifestDecodeRejectsOversizedBodies() {
        let padding = String(repeating: " ", count: TonConnectManifest.maxByteCount)
        let body = Data((#"{"url":"https://a.b","name":"x","iconUrl":"https://a.b/i.png"}"# + padding).utf8)

        #expect(throws: TonConnectError.manifestContentError("manifest exceeds \(TonConnectManifest.maxByteCount) bytes")) {
            try TonConnectManifest.decode(from: body)
        }
    }

    @Test
    func manifestReportsWhetherItIsServedFromItsClaimedDomain() {
        let manifest = TonConnectManifest(url: URL(string: "https://app.example.com")!, name: "x", iconUrl: URL(string: "https://a.b/i.png")!)

        #expect(manifest.isServedFromAppDomain(manifestUrl: URL(string: "https://app.example.com/tonconnect-manifest.json")!))
        #expect(manifest.isServedFromAppDomain(manifestUrl: URL(string: "https://cdn.app.example.com/m.json")!))
        #expect(!manifest.isServedFromAppDomain(manifestUrl: URL(string: "https://raw.githubusercontent.com/x/m.json")!))
        #expect(!manifest.isServedFromAppDomain(manifestUrl: URL(string: "https://evilapp.example.com/m.json")!), "suffix match must be on a label boundary")
    }

    @Test(arguments: ["1.2.3.4", "127.0.0.1"])
    func appDomainRejectsIPv4Literals(host: String) {
        #expect(!TonConnectManifest.isValidAppDomain(host))
    }

    // MARK: - BoC: depth

    @Test
    func bocPreflightRejectsTreesDeeperThanTheCap() throws {
        func chain(_ depth: Int) throws -> Data {
            var cell = try Builder().store(uint: 1, bits: 8).endCell()
            for _ in 0 ..< depth {
                cell = try Builder().store(ref: cell).endCell()
            }
            return try cell.toBoc(idx: false, crc32: false)
        }

        #expect(throws: Never.self) { try TonConnectBoc.preflight(try chain(TonConnectBoc.maxDepth)) }
        #expect(throws: TonConnectBoc.PreflightError.tooDeep) { try TonConnectBoc.preflight(try chain(TonConnectBoc.maxDepth + 1)) }
    }
}
