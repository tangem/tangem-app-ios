//
//  HederaAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoKit
import Testing
import class WalletCore.PrivateKey
import TangemNetworkUtils
@testable import BlockchainSdk

@Suite(.serialized)
struct HederaAddressTests {
    @Test
    func testHederaEd25519() throws {
        // EdDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x302e020100300506032b657004220420ed05eaccdb9b54387e986166eae8f7032684943d28b2894db1ee0ff047c52451")

        // Hedera EdDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/e0cd39c84ab189d59a6bcedcf16e4102d7bb8beb/packages/cryptography/src/Ed25519PrivateKey.js#L8
        let hederaDerPrefixPrivate = Data(hexString: "0x302e020100300506032b657004220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try #require(PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .ed25519, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    @Test
    func testHederaEd25519Slip0010() throws {
        // EdDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x302e020100300506032b657004220420ed05eaccdb9b54387e986166eae8f7032684943d28b2894db1ee0ff047c52451")

        // Hedera EdDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/e0cd39c84ab189d59a6bcedcf16e4102d7bb8beb/packages/cryptography/src/Ed25519PrivateKey.js#L8
        let hederaDerPrefixPrivate = Data(hexString: "0x302e020100300506032b657004220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try #require(PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .ed25519, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    @Test
    func testHederaSecp256k1() throws {
        // ECDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x3030020100300706052b8104000a04220420e507077d8d5bab32debcbbc651fc4ca74660523976502beabee15a1662d77ed1")

        // Hedera ECDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/f65ab2a4cf5bb026fc47fcf8955e81c2b82a6ff3/packages/cryptography/src/EcdsaPrivateKey.js#L7
        let hederaDerPrefixPrivate = Data(hexString: "0x3030020100300706052b8104000a04220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try #require(PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .secp256k1, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    func testHederaAddressGeneration(blockchain: Blockchain, privateKey: WalletCore.PrivateKey) throws {
        let publicKeyRaw = privateKey.getPublicKeyByType(pubkeyType: try .init(blockchain)).data
        let publicKey = Wallet.PublicKey(seedKey: publicKeyRaw, derivationType: nil)

        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        // Both ECDSA and EdDSA are supported
        _ = try addressService.makeAddress(for: publicKey, with: .default)
        _ = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        _ = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        _ = try addressService.makeAddress(from: Keys.AddressesKeys.edKey)

        // Actual address (i.e. Account ID) for Hedera is requested asynchronously from the network/local storage,
        // therefore the address service returns an empty string, this is perfectly fine
        let expectedAddress = ""
        let address = try addressService.makeAddress(for: publicKey, with: .default)

        #expect(AddressType.default.defaultLocalizedName == address.localizedName)
        #expect(expectedAddress == address.value)
    }

    /// Includes account IDs with checksums from https://hips.hedera.com/hip/hip-15
    func testHederaAddressValidation(blockchain: Blockchain) throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        #expect(addressService.validate("0.0.123"))
        #expect(addressService.validate("0.0.123-vfmkw"))
        #expect(addressService.validate("0.0.1234567890-zbhlt"))
        #expect(addressService.validate("0.0.9223372036854775807")) // Account number part fits Int64
        #expect(!addressService.validate("0.0.18446744073709551615")) // Account number part exceeds Int64
        #expect(addressService.validate("0x000000000000000000000000000000000087da23")) // Hedera supports EVM addresses (but only hedera-compatible)
        #expect(!addressService.validate("0xf3DbcEeedDC4BBd1B66492B66EC0B8eC317b511B"))

        #expect(addressService.validate("0.0.302d300706052b8104000a03220002d588ec1000770949ab77516c77ee729774de1c8fe058cab6d64f1b12ffc8ff07")) // Account Alias

        #expect(!addressService.validate("0.0.123-abcde"))
        #expect(!addressService.validate("0.0.123-VFMKW"))
        #expect(!addressService.validate("0.0.123-vFmKw"))
        #expect(!addressService.validate("0.0.123#vfmkw"))
        #expect(!addressService.validate("0.0.123vfmkw"))
        #expect(!addressService.validate("0.0.123 - vfmkw"))
        #expect(!addressService.validate("0.123"))
        #expect(!addressService.validate("0.0.123."))
        #expect(!addressService.validate("0.0.123-vf"))
        #expect(!addressService.validate("0.0.123-vfm-kw"))
        #expect(!addressService.validate("0.0.123-vfmkwxxxx"))
        #expect(!addressService.validate("0.0.18446744073709551616")) // Max length of the account number part is 8 bytes (2^64 - 1)
        #expect(!addressService.validate("0xf64a1db2f124aaa4cd7b58d3d7f66774f9770c6")) // Hedera supports EVM addresses
        #expect(!addressService.validate("0xf64a1db2f124aaa4cd7b58d3d7f66774f9770c6ee")) // Hedera supports EVM addresses
        #expect(!addressService.validate("0.0.402d300706052b8104000a03220002d588ec1000770949ab77516c77ee729774de1c8fe058cab6d64f1b12ffc8ff07")) // Account Alias
        #expect(!addressService.validate(""))
    }

    @Test
    func hederaCustomTokenNormalizedAddressResolution() async throws {
        let resolver = makeHederaContractAddressResolver(
            providerConfiguration: makeMockProviderConfiguration(statusCode: 200, body: "{}"),
            baseURLOverride: try #require(URL(string: "https://unit-test.hedera"))
        )
        let address = "0.0.123456"

        let resolved = try await resolver.resolve(address)
        #expect(resolved.lookupAddress == address)
        #expect(resolved.storageAddress == address)
        #expect(!resolved.isERC20)
    }

    @Test
    func hederaCustomTokenZeroPrefixEVMConversion() async throws {
        let resolver = makeHederaContractAddressResolver(
            providerConfiguration: makeMockProviderConfiguration(statusCode: 200, body: "{}"),
            baseURLOverride: try #require(URL(string: "https://unit-test.hedera"))
        )
        let evmAddress = "0x00000000000000000000000000000000000004d2"

        let resolved = try await resolver.resolve(evmAddress)
        #expect(resolved.lookupAddress == "0.0.1234")
        #expect(resolved.storageAddress == "0.0.1234")
        #expect(!resolved.isERC20)
    }

    @Test
    func hederaCustomTokenMirrorLookupConversion() async throws {
        let providerConfiguration = makeMockProviderConfiguration(
            statusCode: 200,
            body: #"{"contract_id":"0.0.424242"}"#
        )
        let resolver = makeHederaContractAddressResolver(
            providerConfiguration: providerConfiguration,
            baseURLOverride: try #require(URL(string: "https://unit-test.hedera"))
        )

        let evmAddress = "0xf3DbcEeedDC4BBd1B66492B66EC0B8eC317b511B"
        let resolved = try await resolver.resolve(evmAddress)
        #expect(resolved.lookupAddress == "0.0.424242")
        #expect(resolved.storageAddress == "0xf3dbceeeddc4bbd1b66492b66ec0b8ec317b511b")
        #expect(resolved.isERC20)
    }

    @Test
    func hederaHTSTokenTypeDetection() async throws {
        let responseBody = #"{"custom_fees":{"fixed_fees":[],"fractional_fees":[]}}"#
        let networkService = makeHederaNetworkService(
            providerConfiguration: makeMockProviderConfiguration(statusCode: 200, body: responseBody),
            baseURLOverride: try #require(URL(string: "https://unit-test.hedera"))
        )

        let tokenType = try await networkService.getTokenType(tokenAddress: "0.0.456858").async()

        #expect(tokenType == .hts)
    }

    @Test
    func hederaERC20TokenTypeDetection() async throws {
        let responseBody = #"{"_status":{"messages":[{"message":"Not found"}]}}"#
        let networkService = makeHederaNetworkService(
            providerConfiguration: makeMockProviderConfiguration(statusCode: 404, body: responseBody),
            baseURLOverride: try #require(URL(string: "https://unit-test.hedera"))
        )

        let tokenType = try await networkService.getTokenType(tokenAddress: "0.0.1055414").async()

        #expect(tokenType == .erc20)
    }

    @Test
    func hederaTokenTypeDetectionRejectsUnrelatedNotFoundResponse() async throws {
        let responseBody = #"{"_status":{"messages":[{"message":"Account not found"}]}}"#
        let networkService = makeHederaNetworkService(
            providerConfiguration: makeMockProviderConfiguration(statusCode: 404, body: responseBody),
            baseURLOverride: try #require(URL(string: "https://unit-test.hedera"))
        )

        await #expect(throws: (any Error).self) {
            _ = try await networkService.getTokenType(tokenAddress: "0.0.1055414").async()
        }
    }

    @Test
    func hederaERC20MetadataResolutionFromContractId() async throws {
        let evmAddress = "0x7fc8e36f6e8f222bb3d57d06c9f2c14e6a5392ef"
        let providerConfiguration = makeMockProviderConfiguration(statusCode: 200, body: "{}")
        MockURLProtocol.responseProvider = { request in
            if request.url?.path.contains("/tokens/") == true {
                let body = #"{"_status":{"messages":[{"message":"Not found"}]}}"#
                return (404, Data(body.utf8))
            }

            let body = #"{"contract_id":"0.0.1055414","evm_address":"\#(evmAddress)"}"#
            return (200, Data(body.utf8))
        }

        let networkService = makeHederaNetworkService(
            providerConfiguration: providerConfiguration,
            baseURLOverride: try #require(URL(string: "https://unit-test.hedera"))
        )
        let resolver = HederaTokenMetadataResolver(networkService: networkService)

        let metadata = try await resolver.resolve(contractAddress: "0.0.1055414")

        #expect(metadata.type == .erc20)
        #expect(metadata.contractId == "0.0.1055414")
        #expect(metadata.evmAddress == evmAddress)
    }
}

private extension HederaAddressTests {
    func makeHederaContractAddressResolver(
        providerConfiguration: TangemProviderConfiguration,
        baseURLOverride: URL
    ) -> any ContractAddressResolver {
        let networkService = makeHederaNetworkService(
            providerConfiguration: providerConfiguration,
            baseURLOverride: baseURLOverride
        )

        return HederaContractAddressResolver(
            isTestnet: false,
            networkService: networkService
        )
    }

    func makeHederaNetworkService(
        providerConfiguration: TangemProviderConfiguration,
        baseURLOverride: URL
    ) -> HederaNetworkService {
        let restProvider = HederaRESTNetworkProvider(
            targetConfiguration: NodeInfo(url: baseURLOverride),
            providerConfiguration: providerConfiguration
        )
        let consensusProvider = HederaConsensusNetworkProvider(
            isTestnet: false,
            timeout: providerConfiguration.urlSessionConfiguration.timeoutIntervalForRequest
        )
        let networkService = HederaNetworkService(
            consensusProvider: consensusProvider,
            restProviders: [restProvider]
        )
        return networkService
    }

    func makeMockProviderConfiguration(statusCode: Int, body: String) -> TangemProviderConfiguration {
        MockURLProtocol.responseData = Data(body.utf8)
        MockURLProtocol.statusCode = statusCode
        MockURLProtocol.responseProvider = nil

        let configuration = URLSessionConfiguration.ephemeral.copy() as! URLSessionConfiguration
        configuration.protocolClasses = [MockURLProtocol.self]
        return TangemProviderConfiguration(
            logOptions: nil,
            urlSessionConfiguration: configuration
        )
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData = Data()
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var responseProvider: ((URLRequest) -> (statusCode: Int, data: Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            return
        }

        let responsePayload = Self.responseProvider?(request) ?? (
            statusCode: Self.statusCode,
            data: Self.responseData
        )
        let response = HTTPURLResponse(
            url: url,
            statusCode: responsePayload.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: responsePayload.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
