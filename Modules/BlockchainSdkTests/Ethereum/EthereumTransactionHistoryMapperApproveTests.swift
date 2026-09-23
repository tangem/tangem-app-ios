//
//  EthereumTransactionHistoryMapperApproveTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk
import Testing

/// Covers the step the calldata decoder can't: pairing an `approve` with the token it approves, which is the
/// transaction's destination contract rather than the wallet's own currency, and scaling by that token's decimals.
struct EthereumTransactionHistoryMapperApproveTests {
    private let blockchain = Blockchain.ethereum(testnet: false)
    private let walletAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
    private let tokenContract = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    private let spender = "0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae"

    /// `approve(0x1231…4eae, 28000000)` — the example from the ticket.
    private var limitedCalldata: String {
        ["0x095ea7b3", "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae", "0000000000000000000000000000000000000000000000000000000001ab3f00"].joined()
    }

    private var unlimitedCalldata: String {
        ["0x095ea7b3", "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae", "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"].joined()
    }

    @Test("Scales a limited allowance by the approved token's decimals, not the coin's")
    func limitedApproveIsScaledByTokenDecimals() throws {
        let records = try map(calldata: limitedCalldata, tokens: [.usdt(contract: tokenContract)])

        #expect(records.count == 1)
        // 28_000_000 raw over USDT's 6 decimals — as ETH's 18 it would have been 0.000000000028.
        #expect(records[0].type == .approve(.init(spender: spender, symbol: "USDT", allowance: .limited(28))))
    }

    @Test("Reports a zero allowance as a revoke")
    func zeroApproveIsRevoked() throws {
        let calldata = ["0x095ea7b3", "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae", String(repeating: "0", count: 64)].joined()
        let records = try map(calldata: calldata, tokens: [.usdt(contract: tokenContract)])

        #expect(records.count == 1)
        #expect(records[0].type == .approve(.init(spender: spender, symbol: "USDT", allowance: .revoked)))
    }

    @Test("Reports a zero allowance as a revoke even when the token is unknown, since no decimals are needed")
    func zeroApproveWithoutKnownTokenIsRevoked() throws {
        let calldata = ["0x095ea7b3", "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae", String(repeating: "0", count: 64)].joined()
        let records = try map(calldata: calldata, tokens: [])

        #expect(records[0].type == .approve(.init(spender: spender, symbol: nil, allowance: .revoked)))
    }

    @Test("Reports the uint256 maximum as an unlimited allowance")
    func unlimitedApproveIsRecognized() throws {
        let records = try map(calldata: unlimitedCalldata, tokens: [.usdt(contract: tokenContract)])

        #expect(records.count == 1)
        #expect(records[0].type == .approve(.init(spender: spender, symbol: "USDT", allowance: .unlimited)))
    }

    @Test("Keeps the raw allowance when the approved token isn't among the address's tokens")
    func limitedApproveWithoutKnownTokenIsUnscaled() throws {
        let records = try map(calldata: limitedCalldata, tokens: [])

        #expect(records.count == 1)
        #expect(records[0].type == .approve(.init(spender: spender, symbol: nil, allowance: .unscaled(28_000_000))))
    }

    @Test("An unlimited allowance needs no decimals, so it survives an unknown token")
    func unlimitedApproveWithoutKnownTokenStaysUnlimited() throws {
        let records = try map(calldata: unlimitedCalldata, tokens: [])

        #expect(records.count == 1)
        #expect(records[0].type == .approve(.init(spender: spender, symbol: nil, allowance: .unlimited)))
    }

    @Test("Matches the token contract case-insensitively")
    func tokenContractIsMatchedCaseInsensitively() throws {
        let records = try map(calldata: limitedCalldata, tokens: [.usdt(contract: tokenContract.lowercased())])

        guard case .approve(let approve) = records[0].type else {
            Issue.record("Expected an approve, got \(records[0].type)")
            return
        }

        #expect(approve.symbol == "USDT")
    }

    @Test("Leaves a transfer without any approve information")
    func transferCarriesNoApprove() throws {
        let calldata = ["0xa9059cbb", "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae", "0000000000000000000000000000000000000000000000000000000001ab3f00"].joined()
        let records = try map(calldata: calldata, tokens: [.usdt(contract: tokenContract)])

        #expect(records.count == 1)
        #expect(records[0].type == .transfer)
    }

    // MARK: - Helpers

    private func map(calldata: String, tokens: [BlockBookAddressResponse.Token]) throws -> [TransactionRecord] {
        let mapper = EthereumTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(calldata: calldata, tokens: tokens)

        return try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)
    }

    private func makeResponse(calldata: String, tokens: [BlockBookAddressResponse.Token]) -> BlockBookAddressResponse {
        BlockBookAddressResponse(
            page: 1,
            totalPages: 1,
            itemsOnPage: 25,
            address: walletAddress,
            balance: "0",
            unconfirmedBalance: nil,
            unconfirmedTxs: nil,
            txs: 1,
            nonTokenTxs: nil,
            // An approve is sent to the token contract and moves no coin value.
            transactions: [.init(from: walletAddress, to: tokenContract, calldata: calldata)],
            tokens: tokens
        )
    }
}

// MARK: - Test fixtures

private extension BlockBookAddressResponse.Token {
    static func usdt(contract: String) -> Self {
        .init(type: "ERC20", id: nil, name: "Tether USD", contract: contract, transfers: 1, symbol: "USDT", decimals: 6, balance: "0")
    }
}

private extension BlockBookAddressResponse.Transaction {
    init(from: String, to: String, calldata: String) {
        self.init(
            txid: "0xdeadbeef",
            contractType: nil,
            contractName: nil,
            version: nil,
            vin: [.init(address: from)],
            vout: [.init(address: to)],
            blockHash: nil,
            blockHeight: 1,
            confirmations: 1,
            blockTime: 1_700_000_000,
            value: "0",
            valueIn: nil,
            fees: "210000",
            hex: nil,
            tokenTransfers: nil,
            ethereumSpecific: .init(status: .ok, nonce: 1, gasLimit: nil, gasUsed: nil, gasPrice: nil, data: calldata, parsedData: nil),
            chainExtraData: nil,
            tronTXReceipt: nil,
            fromAddress: nil,
            toAddress: nil,
            voteList: nil
        )
    }
}

private extension BlockBookAddressResponse.Vin {
    init(address: String) {
        self.init(txid: nil, sequence: nil, n: 0, addresses: [address], isAddress: true, value: nil, hex: nil, vout: nil, isOwn: nil)
    }
}

private extension BlockBookAddressResponse.Vout {
    init(address: String) {
        self.init(value: "0", n: 0, hex: nil, addresses: [address], isAddress: true, spent: nil, isOwn: nil)
    }
}
