//
//  EtherscanTransactionHistoryMapperApproveTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

/// The Etherscan history carries the calldata but nothing about the approved token, so only the allowances that need
/// no decimals are recoverable there. A limited one stays a plain contract call rather than an approve without amount.
struct EtherscanTransactionHistoryMapperApproveTests {
    private let blockchain = Blockchain.polygon(testnet: false)
    private let walletAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
    private let tokenContract = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
    private let spender = "0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae"

    private var spenderSlot: String { "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae" }

    @Test("Recognizes an unlimited allowance without knowing the token")
    func unlimitedApproveIsRecognized() throws {
        let calldata = ["0x095ea7b3", spenderSlot, String(repeating: "f", count: 64)].joined()
        let records = try map(calldata: calldata)

        #expect(records.count == 1)
        #expect(records[0].type == .approve(.init(spender: spender, symbol: nil, allowance: .unlimited)))
    }

    @Test("Recognizes a revoke without knowing the token")
    func zeroApproveIsRevoked() throws {
        let calldata = ["0x095ea7b3", spenderSlot, String(repeating: "0", count: 64)].joined()
        let records = try map(calldata: calldata)

        #expect(records[0].type == .approve(.init(spender: spender, symbol: nil, allowance: .revoked)))
    }

    @Test("Leaves a limited allowance as a plain contract call, since its decimals are unknown here")
    func limitedApproveStaysContractCall() throws {
        let calldata = ["0x095ea7b3", spenderSlot, "0000000000000000000000000000000000000000000000000000000001ab3f00"].joined()
        let records = try map(calldata: calldata)

        #expect(records[0].type == .contractMethodIdentifier(id: ApproveERC20TokenMethod.methodId))
    }

    @Test("Leaves a transaction without calldata alone")
    func missingCalldataIsNotAnApprove() throws {
        let records = try map(calldata: nil)

        #expect(records[0].type == .contractMethodIdentifier(id: ApproveERC20TokenMethod.methodId))
    }

    // MARK: - Helpers

    private func map(calldata: String?) throws -> [TransactionRecord] {
        let mapper = EtherscanTransactionHistoryMapper(blockchain: blockchain)
        let response = EtherscanTransactionHistoryResult(
            status: "1",
            message: nil,
            result: .transactions([
                .approve(from: walletAddress, to: tokenContract, input: calldata),
            ])
        )

        return try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)
    }
}

// MARK: - Test fixtures

private extension EtherscanTransactionHistoryResult.Transaction {
    /// An approve moves no coin value and is sent to the token's contract, which is what makes it a contract call.
    static func approve(from: String, to: String, input: String?) -> Self {
        .init(
            confirmations: "10",
            contractAddress: nil,
            from: from,
            functionName: "approve(address spender, uint256 value)",
            methodId: ApproveERC20TokenMethod.methodId,
            gasPrice: "30000000000",
            gasUsed: "46000",
            hash: "0xdeadbeef",
            input: input,
            isError: "0",
            timeStamp: "1700000000",
            to: to,
            txReceiptStatus: "1",
            value: "0"
        )
    }
}
