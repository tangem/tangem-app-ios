//
//  EtherscanTransactionHistoryProviderTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemNetworkUtils
@testable import BlockchainSdk

@Suite("Etherscan history of a token", .timeLimit(.minutes(1)))
struct EtherscanTransactionHistoryProviderTests {
    @Test("A token row of a wrapped call gets its calldata looked up and is typed by the call inside")
    func tokenRowOfAWrappedCallIsUnwrapped() async throws {
        let provider = EtherscanTransactionHistoryProvider(
            mapper: EtherscanTransactionHistoryMapper(blockchain: .polygon(testnet: false)),
            networkConfiguration: makeNetworkConfiguration(),
            targetConfiguration: .etherscan(chainId: 137, apiKey: "apiKey", baseURL: URL(string: "https://etherscan.test/v2")!)
        )
        let request = TransactionHistory.Request(
            address: EtherscanTokenHistoryURLProtocol.walletAddress,
            amountType: .token(value: EtherscanTokenHistoryURLProtocol.token)
        )

        let response = try await provider.loadTransactionHistory(request: request).async()

        #expect(response.records.map(\.type) == [.contractMethodIdentifier(id: YieldModuleUpgradeCalldata.yieldSendMethodId)])
    }
}

// MARK: - Helpers

private extension EtherscanTransactionHistoryProviderTests {
    func makeNetworkConfiguration() -> TangemProviderConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EtherscanTokenHistoryURLProtocol.self]

        return TangemProviderConfiguration(logOptions: nil, urlSessionConfiguration: configuration)
    }
}

// MARK: - Stubs

private final class EtherscanTokenHistoryURLProtocol: URLProtocol {
    static let walletAddress = "0x179d3bc82a5d8c0b8f6a2a7e1d4b5c6e7f8a9b0c"
    static let token = Token(name: "USDT0", symbol: "USDT0", contractAddress: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F", decimalCount: 6)

    private static let transactionHash = "0x89fdc2d59fb40fb8ca82e88ac10271c8734ab0ec7ef715cb0d84541378586eeb"
    private static let recipient = "0xe8d5849d4ea5335775e881bb076ed172e8612dd3"

    private static var calldata: String {
        YieldModuleUpgradeCalldata.wrapping(
            YieldModuleUpgradeCalldata.yieldSend(token: token.contractAddress, to: recipient, amount: 100_000),
            implementation: YieldModuleUpgradeCalldata.v3Implementation
        )
    }

    private static func body(forAction action: String) -> String? {
        switch action {
        case "tokentx":
            return #"""
            {"status":"1","message":"OK","result":[{"confirmations":"10","contractAddress":"\#(token.contractAddress)","from":"\#(walletAddress)","functionName":"upgradeToAndCall(address newImplementation, bytes data)","methodId":"\#(UpgradeToAndCallMethod.methodId)","gasPrice":"30000000000","gasUsed":"396754","hash":"\#(transactionHash)","input":"deprecated","timeStamp":"1761725000","to":"\#(recipient)","value":"100000"}]}
            """#
        case "eth_getTransactionByHash":
            return #"{"jsonrpc":"2.0","id":1,"result":{"hash":"\#(transactionHash)","input":"\#(calldata)"}}"#
        default:
            return nil
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard
            let url = request.url,
            let action = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "action" })?.value,
            let body = Self.body(forAction: action),
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
