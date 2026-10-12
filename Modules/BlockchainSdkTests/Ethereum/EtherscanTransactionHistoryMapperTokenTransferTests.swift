//
//  EtherscanTransactionHistoryMapperTokenTransferTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

/// A token transfer reaches the coin history as the call that paid for it: the coin endpoint reports no token
/// transfer of its own, so what moved is recovered from the calldata and left for the app to name.
struct EtherscanTransactionHistoryMapperTokenTransferTests {
    private let blockchain = Blockchain.polygon(testnet: false)
    private let walletAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
    private let tokenContract = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
    private let recipient = "0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae"

    private var recipientSlot: String { "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae" }

    @Test("Recovers the transfer a coin transaction paid for from its calldata")
    func transferIsRecoveredFromCalldata() throws {
        let calldata = [TransferERC20TokenMethod.methodId, recipientSlot, "0000000000000000000000000000000000000000000000000000000001ab3f00"].joined()

        let transfer = try #require(try map(calldata: calldata).first?.tokenTransfers.singleElement)

        #expect(transfer.source == walletAddress)
        #expect(transfer.destination == recipient)
        // Raw, as the token's decimals are unknown here — the same as what the token endpoint reports.
        #expect(transfer.amount == 28_000_000)
        #expect(transfer.contract == tokenContract)
        #expect(transfer.symbol == nil)
        #expect(transfer.decimals == nil)
    }

    @Test("A call that is not a transfer moves no token")
    func anotherCallCarriesNoTransfer() throws {
        let calldata = ["0x095ea7b3", recipientSlot, String(repeating: "f", count: 64)].joined()

        #expect(try map(calldata: calldata).first?.tokenTransfers.isEmpty == true)
    }

    @Test("A transaction without calldata moves no token")
    func missingCalldataCarriesNoTransfer() throws {
        #expect(try map(calldata: nil).first?.tokenTransfers.isEmpty == true)
    }

    // MARK: - Helpers

    private func map(calldata: String?) throws -> [TransactionRecord] {
        let mapper = EtherscanTransactionHistoryMapper(blockchain: blockchain)
        let response = EtherscanTransactionHistoryResult(
            status: "1",
            message: nil,
            result: .transactions([
                .tokenTransfer(from: walletAddress, to: tokenContract, input: calldata),
            ])
        )

        return try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)
    }
}

// MARK: - Test fixtures

private extension EtherscanTransactionHistoryResult.Transaction {
    /// In the coin history the transfer is a call to the token's contract that moves no coin value. The endpoint
    /// leaves the contract address empty there rather than omitting it.
    static func tokenTransfer(from: String, to: String, input: String?) -> Self {
        .init(
            confirmations: "10",
            contractAddress: "",
            from: from,
            functionName: "transfer(address _to, uint256 _value)",
            methodId: TransferERC20TokenMethod.methodId,
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
