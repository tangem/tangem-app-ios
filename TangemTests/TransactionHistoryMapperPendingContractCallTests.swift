//
//  TransactionHistoryMapperPendingContractCallTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("Pending transactions in the Send Recent suggestions")
struct TransactionHistoryMapperPendingContractCallTests {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let walletAddress = "0x1111111111111111111111111111111111111111"
    private static let destination = "0x2222222222222222222222222222222222222222"
    private static let depositCallData = Data([0x09, 0x21, 0xEC, 0xD4])

    @Test("A pending contract call that sends ETH, such as a dApp call through WalletConnect, is not suggested as a recipient")
    func pendingContractCallIsNotSuggested() {
        let record = makeRecord(params: EthereumTransactionParams(data: Self.depositCallData))

        #expect(makeSUT().mapSuggestedRecord(record) == nil)
    }

    @Test("A pending ETH transfer with no transaction parameters is still suggested")
    func pendingTransferWithoutParamsIsSuggested() {
        let record = makeRecord(params: nil)

        #expect(makeSUT().mapSuggestedRecord(record)?.address == Self.destination)
    }

    @Test("A pending ETH transfer that carries only a nonce is still suggested")
    func pendingTransferWithNonceIsSuggested() {
        let record = makeRecord(params: EthereumTransactionParams(nonce: 7))

        #expect(makeSUT().mapSuggestedRecord(record)?.address == Self.destination)
    }

    @Test("A pending contract call that sends ETH is listed as a contract call, a plain ETH transfer as a transfer to its recipient")
    func pendingContractCallIsListedAsContract() {
        let mapper = PendingTransactionRecordMapper(formatter: BalanceFormatter())

        let call = mapper.mapToTransactionViewModel(makePending(params: EthereumTransactionParams(data: Self.depositCallData)))
        let transfer = mapper.mapToTransactionViewModel(makePending(params: nil))

        #expect(call.interactionAddress == .contract(Self.destination))
        #expect(transfer.interactionAddress == .user(Self.destination))
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperPendingContractCallTests {
    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "ETH",
            blockchain: Self.blockchain,
            addressesProvider: AddressesProviderStub(walletAddresses: [Self.walletAddress]),
            showSign: true,
            isToken: false,
            stakingNetwork: nil
        )
    }

    func makeRecord(params: EthereumTransactionParams?) -> TransactionRecord {
        PendingTransactionRecordMapper(formatter: BalanceFormatter())
            .mapToTransactionRecord(pending: makePending(params: params))
    }

    func makePending(params: EthereumTransactionParams?) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: "0xHash",
            source: Self.walletAddress,
            destination: Self.destination,
            amount: Amount(with: Self.blockchain, type: .coin, value: Decimal(5) / 10),
            fee: Fee(Amount(with: Self.blockchain, type: .coin, value: Decimal(1) / 1000)),
            date: Date(),
            isIncoming: false,
            transactionType: .transfer,
            transactionParams: params
        )
    }
}

// MARK: - Stubs

private struct AddressesProviderStub: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
