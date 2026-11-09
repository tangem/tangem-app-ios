//
//  TronWalletManagerTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemNetworkUtils
@testable import BlockchainSdk

struct TronWalletManagerTests {
    private let blockchain = Blockchain.tron(testnet: false)
    private let loadedToken = Token(name: "Tether", symbol: "USDT", contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", decimalCount: 6)
    private let failingToken = Token(name: "USD Coin", symbol: "USDC", contractAddress: "TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8", decimalCount: 6)

    @Test
    func failedTokenBalanceIsClearedWhileOtherBalancesLoad() async throws {
        let walletManager = try makeWalletManager()
        walletManager.wallet.add(tokenValue: 5, for: failingToken)

        try await walletManager.updateWalletManager(address: Constants.address)

        let amounts = walletManager.wallet.amounts
        #expect(amounts[.coin]?.value == 2)
        #expect(amounts[.token(value: loadedToken)]?.value == 1)
        #expect(amounts[.token(value: failingToken)] == nil)
    }
}

// MARK: - Private implementation

private extension TronWalletManagerTests {
    enum Constants {
        static let address = "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF"
    }

    func makeWalletManager() throws -> TronWalletManager {
        let wallet = Wallet(
            blockchain: blockchain,
            publicKey: .empty,
            addressesProvider: CommonAddressesProvider(
                defaultAddress: PlainAddress(value: Constants.address, type: .default)
            )
        )

        let nodeURL = try #require(URL(string: "https://tron.test"))
        let provider = TronJsonRpcProviderStub(
            node: NodeInfo(url: nodeURL),
            failingContractAddress: failingToken.contractAddress
        )

        let walletManager = TronWalletManager(wallet: wallet)
        walletManager.networkService = TronNetworkService(isTestnet: false, providers: [provider])
        walletManager.txBuilder = TronTransactionBuilder()
        walletManager.addToken(loadedToken)
        walletManager.addToken(failingToken)

        return walletManager
    }
}

// MARK: - Stubs

private struct TronJsonRpcProviderStubError: Error {}

private final class TronJsonRpcProviderStub: TronJsonRpcProvider {
    private let failingContractAddress: String

    init(node: NodeInfo, failingContractAddress: String) {
        self.failingContractAddress = failingContractAddress

        super.init(node: node, configuration: .ephemeralConfiguration)
    }

    override func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        .justWithError(output: TronGetAccountResponse(balance: 2_000_000, address: address))
    }

    override func tokenBalance(address: String, contractAddress: String, parameter: String) -> AnyPublisher<TronTriggerSmartContractResponse, Error> {
        guard contractAddress != failingContractAddress else {
            return .anyFail(error: TronJsonRpcProviderStubError())
        }

        let oneTokenWithSixDecimals = "00000000000000000000000000000000000000000000000000000000000f4240"

        return .justWithError(output: TronTriggerSmartContractResponse(constant_result: [oneTokenWithSixDecimals]))
    }
}
