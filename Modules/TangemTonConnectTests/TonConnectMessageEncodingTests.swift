//
//  TonConnectMessageEncodingTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TonSwift
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectMessageEncodingTests {
    private static let deviceInfo = TonConnectDeviceInfo(
        platform: .iphone,
        appName: "tangem",
        appVersion: "5.30.0",
        features: [
            .sendTransaction(.init(maxMessages: 4)),
            .signData(types: [.text, .binary, .cell]),
        ]
    )

    private func json(_ data: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // MARK: - Incoming

    @Test
    func decodesAppRequestWithStringOrNumericId() throws {
        let string = try TonConnectAppRequest.decode(from: Data(#"{"method":"sendTransaction","params":["{}"],"id":"42"}"#.utf8))
        #expect(string == TonConnectAppRequest(method: .sendTransaction, params: ["{}"], id: "42"))

        let numeric = try TonConnectAppRequest.decode(from: Data(#"{"method":"disconnect","params":[],"id":7}"#.utf8))
        #expect(numeric.method == .disconnect)
        #expect(numeric.id == "7")

        let unknown = try TonConnectAppRequest.decode(from: Data(#"{"method":"signFuture","id":"1"}"#.utf8))
        #expect(unknown.method == .unknown("signFuture"))
        #expect(unknown.params.isEmpty)
        #expect(unknown.method.rawValue == "signFuture")
    }

    @Test
    func appRequestSingleParameterRules() throws {
        #expect(try TonConnectAppRequest(method: .signData, params: ["{\"a\":1}"], id: "1").singleJSONParameter() == Data("{\"a\":1}".utf8))
        #expect(throws: TonConnectError.badRequest("expected exactly one parameter, got 0")) {
            try TonConnectAppRequest(method: .signData, params: [], id: "1").singleJSONParameter()
        }
        #expect(throws: TonConnectError.malformedEnvelope("AppRequest is not valid JSON")) {
            try TonConnectAppRequest.decode(from: Data("nope".utf8))
        }
    }

    @Test
    func signDataPayloadRoundTripsAllVariants() throws {
        let text = try TonConnectSignDataPayload.decode(from: Data(#"{"type":"text","text":"Hi","network":"-239","from":"UQAAA"}"#.utf8))
        #expect(text == TonConnectSignDataPayload(content: .text("Hi"), network: .mainnet, from: "UQAAA"))

        let binary = try TonConnectSignDataPayload.decode(from: Data(#"{"type":"binary","bytes":"3q2+7w=="}"#.utf8))
        #expect(binary.content == .binary(Data([0xDE, 0xAD, 0xBE, 0xEF])))

        let cell = try TonConnectSignDataPayload.decode(from: Data(#"{"type":"cell","schema":"x#00 = X;","cell":"te6cc"}"#.utf8))
        #expect(cell.content == .cell(schema: "x#00 = X;", cellBoc: "te6cc"))

        let reencoded = try json(TonConnectJSON.encode(text))
        #expect(reencoded["type"] as? String == "text")
        #expect(reencoded["text"] as? String == "Hi")
        #expect(reencoded["network"] as? String == "-239")
        #expect(reencoded["from"] as? String == "UQAAA")

        #expect(throws: TonConnectError.badRequest("signData payload is malformed")) {
            try TonConnectSignDataPayload.decode(from: Data(#"{"type":"video","url":"x"}"#.utf8))
        }
        #expect(throws: TonConnectError.badRequest("signData payload is malformed")) {
            try TonConnectSignDataPayload.decode(from: Data(#"{"type":"binary","bytes":"***"}"#.utf8))
        }
    }

    // MARK: - Outgoing

    @Test
    func encodesConnectEventWithItemsAndDeviceInfo() throws {
        let proof = TonConnectProof(timestamp: 1_764_424_242, domain: "app.example.com", signature: Data(repeating: 1, count: 64), payload: "nonce")
        let event = TonConnectConnectEvent.connect(
            id: 0,
            items: [
                .tonAddress(.init(address: "0:abc", network: .mainnet, publicKey: "ff", walletStateInit: "te6cc")),
                .tonProof(proof),
                .error(name: "ton_future", code: .methodNotSupported, message: "Unsupported connect item"),
            ],
            device: Self.deviceInfo
        )

        let object = try json(TonConnectJSON.encode(event))

        #expect(object["event"] as? String == "connect")
        #expect(object["id"] as? Int == 0)
        let payload = try #require(object["payload"] as? [String: Any])
        let items = try #require(payload["items"] as? [[String: Any]])
        #expect(items.count == 3)

        #expect(items[0]["name"] as? String == "ton_addr")
        #expect(items[0]["address"] as? String == "0:abc")
        #expect(items[0]["network"] as? String == "-239")
        #expect(items[0]["publicKey"] as? String == "ff")
        #expect(items[0]["walletStateInit"] as? String == "te6cc")

        #expect(items[1]["name"] as? String == "ton_proof")
        let proofObject = try #require(items[1]["proof"] as? [String: Any])
        #expect(proofObject["timestamp"] as? String == "1764424242")
        #expect(proofObject["payload"] as? String == "nonce")
        #expect(proofObject["signature"] as? String == Data(repeating: 1, count: 64).base64EncodedString())
        let domain = try #require(proofObject["domain"] as? [String: Any])
        #expect(domain["value"] as? String == "app.example.com")
        #expect(domain["lengthBytes"] as? Int == 15)

        #expect(items[2]["name"] as? String == "ton_future")
        let error = try #require(items[2]["error"] as? [String: Any])
        #expect(error["code"] as? Int == 400)

        let device = try #require(payload["device"] as? [String: Any])
        #expect(device["platform"] as? String == "iphone")
        #expect(device["appName"] as? String == "tangem")
        #expect(device["appVersion"] as? String == "5.30.0")
        #expect(device["maxProtocolVersion"] as? Int == 2)
        let features = try #require(device["features"] as? [[String: Any]])
        #expect(features[0]["name"] as? String == "SendTransaction")
        #expect(features[0]["maxMessages"] as? Int == 4)
        #expect(features[0]["extraCurrencySupported"] as? Bool == false)
        #expect(features[0]["itemTypes"] == nil)
        #expect(features[1]["name"] as? String == "SignData")
        #expect(features[1]["types"] as? [String] == ["text", "binary", "cell"])
    }

    @Test
    func encodesConnectError() throws {
        let object = try json(TonConnectJSON.encode(TonConnectConnectEvent.connectError(id: 3, code: .userDeclined, message: "User declined the connection")))

        #expect(object["event"] as? String == "connect_error")
        #expect(object["id"] as? Int == 3)
        let payload = try #require(object["payload"] as? [String: Any])
        #expect(payload["code"] as? Int == 300)
        #expect(payload["message"] as? String == "User declined the connection")
    }

    @Test
    func encodesWalletResponses() throws {
        let send = try json(TonConnectJSON.encode(TonConnectWalletResponse.success(id: "42", result: .sendTransaction(externalMessageBoc: "te6cc"))))
        #expect(send["id"] as? String == "42")
        #expect(send["result"] as? String == "te6cc")

        let signMessage = try json(TonConnectJSON.encode(TonConnectWalletResponse.success(id: "43", result: .signMessage(internalBoc: "te6cc"))))
        #expect((signMessage["result"] as? [String: Any])?["internalBoc"] as? String == "te6cc")

        let disconnect = try json(TonConnectJSON.encode(TonConnectWalletResponse.success(id: "44", result: .disconnect)))
        #expect((disconnect["result"] as? [String: Any])?.isEmpty == true)

        let signData = try json(TonConnectJSON.encode(TonConnectWalletResponse.success(
            id: "45",
            result: .signData(.init(signature: Data([1]), address: "0:aa", timestamp: 5, domain: "a.b", payload: .init(content: .text("t"), network: nil, from: nil)))
        )))
        let result = try #require(signData["result"] as? [String: Any])
        #expect(result["signature"] as? String == "AQ==")
        #expect(result["address"] as? String == "0:aa")
        #expect(result["timestamp"] as? Int == 5)
        #expect(result["domain"] as? String == "a.b")
        #expect((result["payload"] as? [String: Any])?["text"] as? String == "t")

        let failure = try json(TonConnectJSON.encode(TonConnectWalletResponse.failure(id: "46", error: .userDeclined)))
        #expect(failure["id"] as? String == "46")
        let error = try #require(failure["error"] as? [String: Any])
        #expect(error["code"] as? Int == 300)
        #expect(error["message"] as? String == "User declined the request")
        #expect(failure["result"] == nil)
    }

    @Test
    func encodesDisconnectEvent() throws {
        let object = try json(TonConnectJSON.encode(TonConnectDisconnectEvent(id: 2)))

        #expect(object["event"] as? String == "disconnect")
        #expect(object["id"] as? Int == 2)
        #expect((object["payload"] as? [String: Any])?.isEmpty == true)
    }

    @Test
    func errorCodesFollowTheCentralCatalogue() {
        #expect(TonConnectError.badRequest("x").protocolCode == .badRequest)
        #expect(TonConnectError.manifestNotFound.protocolCode == .manifestNotFound)
        #expect(TonConnectError.manifestContentError("x").protocolCode == .manifestContentError)
        #expect(TonConnectError.unknownSession.protocolCode == .unknownApp)
        #expect(TonConnectError.userDeclined.protocolCode == .userDeclined)
        #expect(TonConnectError.methodNotSupported("x").protocolCode == .methodNotSupported)
        #expect(TonConnectError.decryptionFailed.protocolCode == .unknownError)
        #expect(TonConnectError.requestIDNotIncreasing(received: "1", last: "2").protocolCode == .badRequest)
        #expect(TonConnectErrorCode.badRequest.rawValue == 1)
        #expect(TonConnectErrorCode.unknownApp.rawValue == 100)
    }

    // MARK: - Connect event factory

    @Test
    func factoryAnswersEveryRequestedItem() async throws {
        let signer = FakeTonConnectSigner()
        let factory = TonConnectConnectEventFactory(deviceInfo: Self.deviceInfo, now: { Date(timeIntervalSince1970: 1_764_424_242) })
        let request = TonConnectConnectRequest(
            manifestUrl: URL(string: "https://app.example.com/tonconnect-manifest.json")!,
            items: [.tonAddress(network: .mainnet), .tonProof(payload: "nonce"), .unsupported(name: "ton_future")]
        )

        let approval = try await factory.makeApproval(request: request, publicKey: signer.publicKey, network: .mainnet, appDomain: "app.example.com", eventID: 0, signer: signer)

        let expectedAddress = try WalletV4R2(publicKey: signer.publicKey).address()
        #expect(approval.account.address == expectedAddress.toRaw())
        #expect(approval.account.publicKey == signer.publicKey.tonConnectHexString)
        #expect(approval.account.network == .mainnet)

        guard case .connect(let id, let items, let device) = approval.event else {
            Issue.record("expected a connect event")
            return
        }
        #expect(id == 0)
        #expect(device == Self.deviceInfo)
        #expect(items.count == 3)

        guard case .tonAddress(let addressReply) = items[0] else { Issue.record("expected ton_addr"); return }
        #expect(addressReply.address == expectedAddress.toRaw())
        #expect(try Cell.fromBoc(src: Data(base64Encoded: addressReply.walletStateInit)!)[0].hash() == expectedAddress.hash)

        guard case .tonProof(let proof) = items[1] else { Issue.record("expected ton_proof"); return }
        let digest = TonConnectProofMessage.digest(address: expectedAddress, appDomain: "app.example.com", timestamp: 1_764_424_242, payload: "nonce")
        #expect(signer.verify(signature: Data(base64Encoded: proof.signature)!, digest: digest))
        #expect(proof.domain.value == "app.example.com")

        #expect(items[2] == .error(name: "ton_future", code: .methodNotSupported, message: "Unsupported connect item"))
    }

    @Test
    func factoryDoesNotSignWhenProofIsNotRequested() async throws {
        let signer = FakeTonConnectSigner()
        let factory = TonConnectConnectEventFactory(deviceInfo: Self.deviceInfo)
        let request = TonConnectConnectRequest(manifestUrl: URL(string: "https://a.b/m.json")!, items: [.tonAddress(network: nil)])

        let approval = try await factory.makeApproval(request: request, publicKey: signer.publicKey, network: .mainnet, appDomain: "a.b", eventID: 5, signer: signer)

        #expect(signer.signedDigests.isEmpty)
        guard case .connect(let id, let items, _) = approval.event else { Issue.record("expected connect"); return }
        #expect(id == 5)
        #expect(items.count == 1)

        let rejection = factory.makeRejection(eventID: 6, error: .userDeclined)
        #expect(rejection == .connectError(id: 6, code: .userDeclined, message: "User declined the request"))
    }
}
