//
//  TransactionDetailsGaslessFeeTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
import TangemFoundation
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("TransactionDetailsFactory network fee of a gasless transfer")
    final class TransactionDetailsGaslessFeeTests {
        private static let blockchain = Blockchain.polygon(testnet: false)
        private static let walletAddress = "0xwallet"
        private static let recipientAddress = "0xrecipient"

        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        /// A history that lists only this token's own transfers can't name the token the fee was paid in, and the
        /// gas on the record is what the relayer paid, not the wallet.
        @Test("A gasless transfer never shows the relayer's gas as its network fee")
        func theRelayersGasIsNotShown() async throws {
            let content = try await withStubbedDependencies {
                try #require(makeContent(fee: Fee(Amount(with: Self.blockchain, value: 0.00001141))))
            }

            #expect(content.info?.rows.contains { $0.id == "networkFee" } != true)
        }

        @Test("A gasless transfer shows the fee the wallet paid in a token")
        func theFeePaidInATokenIsShown() async throws {
            let feeToken = Token(name: "Tether USD", symbol: "USDT", contractAddress: "0xusdt", decimalCount: 6)
            let content = try await withStubbedDependencies {
                try #require(makeContent(fee: Fee(Amount(with: feeToken, value: 0.037287))))
            }

            #expect(content.info?.rows.contains { $0.id == "networkFee" } == true)
        }

        @Test("The token a gasless fee was paid in is the one the app knows by its contract")
        func theFeeTokenIsResolvedByItsContract() async throws {
            let usdt = ExpressMergeTestDataFactory.ethereumUSDTToken
            auxDataRepository.register(usdt, for: ExpressMergeTestDataFactory.matchingCurrency(for: usdt))
            let usdc = TokenItem.token(
                Token(name: "USD Coin", symbol: "USDC", contractAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", decimalCount: 6),
                .init(.ethereum(testnet: false), derivationPath: nil)
            )
            let row = try await withStubbedDependencies {
                let merger = ExpressMergeTestDataFactory.makeMerger(
                    currentToken: usdc,
                    ownerAddress: Self.walletAddress,
                    feeTokenItem: ExpressMergeTestDataFactory.ethereumToken
                )
                let payment = TransactionRecord(
                    hash: "0xgasless",
                    index: 0,
                    source: .single(.init(address: Self.walletAddress, amount: 10)),
                    destination: .single(.init(address: .user(Self.recipientAddress), amount: 10)),
                    fee: Fee(Amount(with: .ethereum(testnet: false), value: 0.00001141)),
                    status: .confirmed,
                    isOutgoing: true,
                    type: .contractMethodIdentifier(id: "0x4b072692"),
                    date: Date(),
                    tokenTransfers: [
                        .init(
                            source: Self.walletAddress,
                            destination: "0xAf722F46145fbb106379d506ED3a5B96f110c8E5",
                            amount: 37287,
                            name: nil,
                            symbol: nil,
                            decimals: nil,
                            contract: "0xdAC17F958D2ee523a2206206994597C13D831ec7"
                        ),
                    ],
                    nonce: nil
                )

                return try #require(merger.merge(bsdkTransactions: [payment], exchangeTransactions: [], onrampTransactions: []).singleElement)
            }

            #expect(row.fee.amount.currencySymbol == "USDT")
            #expect(row.fee.amount.value == Decimal(string: "0.037287"))
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionDetailsGaslessFeeTests {
    func withStubbedDependencies<T>(_ operation: () throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
            defer { InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository }
            return try operation()
        }
    }

    func makeContent(fee: Fee) -> TransactionDetailsGenericOperationViewData? {
        let record = TransactionRecord(
            hash: "0xgasless",
            index: 0,
            source: .single(.init(address: Self.walletAddress, amount: 10)),
            destination: .single(.init(address: .user(Self.recipientAddress), amount: 10)),
            fee: fee,
            status: .confirmed,
            isOutgoing: true,
            type: .contractMethodIdentifier(id: "0x6234d42b"),
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
        let walletModel = CommonWalletModel.previewWalletModel(history: [record])
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
            currencySymbol: "USDC",
            blockchain: Self.blockchain,
            addressesProvider: walletModel,
            showSign: true,
            isToken: true,
            stakingNetwork: nil
        )
        let transaction = mapper.mapTransactionViewModel(record)
        let addContactHelper = TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(Self.blockchain.networkId),
            contacts: [],
            isAddressBookSynced: true,
            transactionType: transaction.transactionType,
            interactionAddress: transaction.interactionAddress,
            subtitleOwner: transaction.subtitleOwner
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
