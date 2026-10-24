//
//  EtherscanTransactionHistoryTargetTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

struct EtherscanTransactionHistoryTargetTests {
    private let monadChainId = 143
    private let polygonChainId = 137
    private let walletAddress = "0xcc4855a110a53dcf7392620ab5b2da1d9a0c44ed"
    private let tokenContract = "0x3bd359c1119da7da1d913d1c4d2b7c461115433a"

    @Test("The coin history is asked for without a block range")
    func coinHistoryPinsNoBlockRange() throws {
        let parameters = try #require(
            queryParameters(of: .getCoinTransactionHistory(address: walletAddress, page: 1, limit: 20), chainId: monadChainId)
        )

        #expect(parameters["startblock"] == nil)
        #expect(parameters["endblock"] == nil)
        #expect(parameters["action"] as? String == "txlist")
    }

    @Test("The token history is asked for without a block range, which is where the ceiling hurt")
    func tokenHistoryPinsNoBlockRange() throws {
        let parameters = try #require(
            queryParameters(
                of: .getTokenTransactionHistory(address: walletAddress, contract: tokenContract, page: 1, limit: 20),
                chainId: monadChainId
            )
        )

        #expect(parameters["startblock"] == nil)
        #expect(parameters["endblock"] == nil)
        #expect(parameters["action"] as? String == "tokentx")
        #expect(parameters["contractaddress"] as? String == tokenContract)
        #expect(parameters["chainid"] as? Int == monadChainId)
    }

    @Test("No chain carries a block range, however far its head is from the old ceiling")
    func noChainCarriesABlockRange() throws {
        let parameters = try #require(
            queryParameters(
                of: .getTokenTransactionHistory(address: walletAddress, contract: tokenContract, page: 1, limit: 20),
                chainId: polygonChainId
            )
        )

        #expect(parameters["startblock"] == nil)
        #expect(parameters["endblock"] == nil)
    }

    // MARK: - Helpers

    private func queryParameters(of target: EtherscanTransactionHistoryTarget.Target, chainId: Int) -> [String: Any]? {
        let sut = EtherscanTransactionHistoryTarget(
            configuration: .etherscan(chainId: chainId, apiKey: "apikey", baseURL: URL(string: "https://api.etherscan.io")!),
            target: target
        )

        guard case .requestParameters(let parameters, _) = sut.task else {
            return nil
        }

        return parameters
    }
}
