//
//  CosmosFeeTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import TangemFoundation
import TangemNetworkUtils
import class WalletCore.PrivateKey
@testable import BlockchainSdk

struct CosmosFeeTests {
    private let cosmosChain = CosmosChain.cosmos(testnet: false)

    @Test
    func feeIsCalculatedFromGasReportedByHonestNode() async throws {
        let walletManager = try makeWalletManager(nodes: [.honest])

        let fees = try await walletManager.getFee(amount: makeAmount(), destination: Constants.destination).async()

        #expect(fees.map(\.amount.value) == Constants.expectedFeeValues)
        #expect(fees.map { ($0.parameters as? CosmosFeeParameters)?.gas } == [170_246, 170_246, 170_246])
    }

    @Test(arguments: [CosmosNodeStub.overflowingGas, .gasAboveLimit])
    fileprivate func outOfRangeGasSwitchesToNextNode(lyingNode: CosmosNodeStub) async throws {
        let walletManager = try makeWalletManager(nodes: [lyingNode, .honest])

        let fees = try await walletManager.getFee(amount: makeAmount(), destination: Constants.destination).async()

        #expect(fees.map(\.amount.value) == Constants.expectedFeeValues)
        #expect(walletManager.networkService.currentProviderIndex == 1)
    }

    @Test(arguments: [CosmosNodeStub.overflowingGas, .gasAboveLimit])
    fileprivate func outOfRangeGasFromEveryNodeFailsFeeEstimation(lyingNode: CosmosNodeStub) async throws {
        let walletManager = try makeWalletManager(nodes: [lyingNode])

        do {
            _ = try await walletManager.getFee(amount: makeAmount(), destination: Constants.destination).async()

            Issue.record("Expected an error")
        } catch {
            let providerError = try #require(error as? MultiNetworkProviderError)
            #expect(providerError.networkError.errorCode == BlockchainSdkError.failedToGetFee.errorCode)
        }
    }
}

// MARK: - Private implementation

private extension CosmosFeeTests {
    enum Constants {
        static let privateKey = "80e81ea269e66a0a05b11236df7919fb7fbeedba87452d667489d7403a02f005"
        static let destination = "cosmos1zt50azupanqlfam5afhv3hexwyutnukeh4c573"
        static let expectedFeeValues = [1703, 4257, 5108].map { Decimal($0) / 1_000_000 }
    }

    func makeAmount() -> Amount {
        Amount(with: cosmosChain.blockchain, value: 1)
    }

    func makeWalletManager(nodes: [CosmosNodeStub]) throws -> CosmosWalletManager {
        let blockchain = cosmosChain.blockchain
        let privateKey = try #require(PrivateKey(data: Data(hexString: Constants.privateKey)))
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data
        let publicKey = Wallet.PublicKey(seedKey: publicKeyData, derivationType: nil)
        let address = try AddressServiceFactory(blockchain: blockchain)
            .makeAddressService()
            .makeAddress(for: publicKey, with: .default)
        let wallet = Wallet(
            blockchain: blockchain,
            publicKey: publicKey,
            addressesProvider: CommonAddressesProvider(defaultAddress: address)
        )

        let txBuilder = try CosmosTransactionBuilder(publicKey: publicKeyData, cosmosChain: cosmosChain)
        txBuilder.setAccountNumber(1037)
        txBuilder.setSequenceNumber(8)

        let providerConfiguration = makeProviderConfiguration()
        let providers = try nodes.map { node in
            let url = try #require(URL(string: "https://\(node.rawValue)"))

            return CosmosRestProvider(nodeInfo: NodeInfo(url: url), configuration: providerConfiguration)
        }

        let walletManager = CosmosWalletManager(cosmosChain: cosmosChain, wallet: wallet)
        walletManager.txBuilder = txBuilder
        walletManager.networkService = CosmosNetworkService(cosmosChain: cosmosChain, providers: providers)

        return walletManager
    }

    func makeProviderConfiguration() -> TangemProviderConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CosmosSimulateURLProtocol.self]

        return TangemProviderConfiguration(
            logOptions: nil,
            urlSessionConfiguration: configuration
        )
    }
}

// MARK: - Stubs

private enum CosmosNodeStub: String {
    case honest = "honest.cosmos.test"
    case overflowingGas = "overflowing-gas.cosmos.test"
    case gasAboveLimit = "gas-above-limit.cosmos.test"

    var gasUsed: String {
        switch self {
        case .honest:
            return "85123"
        case .overflowingGas:
            return "18446744073709551615"
        case .gasAboveLimit:
            return "1000000001"
        }
    }
}

private final class CosmosSimulateURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard
            let url = request.url,
            let node = url.host.flatMap(CosmosNodeStub.init(rawValue:)),
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let body = #"{"gas_info":{"gas_used":"\#(node.gasUsed)"}}"#

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
