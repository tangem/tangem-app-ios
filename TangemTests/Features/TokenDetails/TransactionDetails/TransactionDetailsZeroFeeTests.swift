//
//  TransactionDetailsZeroFeeTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
import TangemFoundation
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("TransactionDetailsFactory network fee nobody paid")
    final class TransactionDetailsZeroFeeTests {
        private static let tron = Blockchain.tron(testnet: false)
        private static let walletAddress = "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"
        private static let contractAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"

        private let previousAuxDataRepository: TransactionHistoryAuxDataRepository
        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        init() {
            previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
        }

        deinit {
            InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository
        }

        @Test("A Tron transaction that cost no fee shows no network fee", arguments: [Decimal.zero, 1])
        func aZeroTronFeeIsNotShown(movedCoin: Decimal) throws {
            let content = try #require(makeContent(fee: 0, movedCoin: movedCoin, blockchain: Self.tron))

            #expect(content.info?.rows.contains { $0.id == "networkFee" } != true)
        }

        @Test("A zero fee outside Tron is still shown")
        func aZeroFeeOutsideTronIsShown() throws {
            let content = try #require(makeContent(fee: 0, movedCoin: 1, blockchain: .ethereum(testnet: false)))

            #expect(content.info?.rows.contains { $0.id == "networkFee" } == true)
        }

        @Test("A transfer that cost a fee shows it")
        func aFeeIsShown() throws {
            let content = try #require(makeContent(fee: 0.345, movedCoin: 1, blockchain: Self.tron))

            #expect(content.info?.rows.contains { $0.id == "networkFee" } == true)
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionDetailsZeroFeeTests {
    func makeContent(fee: Decimal, movedCoin: Decimal, blockchain: Blockchain) -> TransactionDetailsGenericOperationViewData? {
        let record = TransactionRecord(
            hash: "trc20transfer",
            index: 0,
            source: .single(.init(address: Self.walletAddress, amount: movedCoin)),
            destination: .single(.init(address: .contract(Self.contractAddress), amount: movedCoin)),
            fee: Fee(Amount(with: blockchain, value: fee)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: Date(),
            tokenTransfers: [
                .init(
                    source: Self.walletAddress,
                    destination: "TQrY8tryqsYVCYS3MFbtffiPp2ccyn4STm",
                    amount: 1_000_000,
                    name: "Tether USD",
                    symbol: "USDT",
                    decimals: 6,
                    contract: Self.contractAddress
                ),
            ],
            nonce: nil
        )
        let walletModel = CommonWalletModel.previewWalletModel(history: [record], blockchain: blockchain)
        let userWalletInfo = UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
        let context = TransactionDetailsContext(walletModel: walletModel, userWalletInfo: userWalletInfo, isAccountsMode: false)
        let mapper = TransactionHistoryMapper(
            currencySymbol: blockchain.currencySymbol,
            blockchain: blockchain,
            addressesProvider: walletModel,
            showSign: true,
            isToken: false,
            stakingNetwork: nil
        )
        let transaction = mapper.mapTransactionViewModel(record)
        let addContactHelper = TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(blockchain.networkId),
            contacts: [],
            isAddressBookSynced: true,
            transactionType: transaction.transactionType,
            interactionAddress: transaction.interactionAddress
        )

        let content = TransactionDetailsFactory.reduce(
            transaction: transaction,
            record: record,
            cryptoAmount: 0,
            context: context,
            addContactHelper: addContactHelper
        ).content

        guard case .generic(let data) = content else {
            return nil
        }

        return data
    }
}
