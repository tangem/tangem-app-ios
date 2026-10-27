//
//  TransactionDetailsFailedNetworkFeeTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
import TangemFoundation
import TangemLocalization
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("TransactionDetailsFactory network fee of a failed transaction")
    final class TransactionDetailsFailedNetworkFeeTests {
        private static let ethereum = Blockchain.ethereum(testnet: false)
        private static let walletAddress = "0xWalletAddress"
        private static let contractAddress = "0xContractAddress"

        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        @Test("The fee a failed transaction cost is shown as charged, not struck through")
        func theFeeOfAFailedTransactionIsCharged() async throws {
            let details = await withStubbedDependencies {
                makeDetails(status: .failed)
            }
            let tokens = try #require(singleTokens(in: details.content))

            #expect(details.header.title == Localization.commonNetworkFeeTitle)
            #expect(details.header.titleStyle == .neutral)
            #expect(details.header.operationIcon.status == .confirmed)
            #expect(!tokens.isAmountStrikethrough)
        }

        @Test("The fee of a pending transaction stays pending")
        func theFeeOfAPendingTransactionIsPending() async throws {
            let details = await withStubbedDependencies {
                makeDetails(status: .unconfirmed)
            }

            #expect(details.header.titleStyle == .active)
            #expect(details.header.operationIcon.status == .inProgress)
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionDetailsFailedNetworkFeeTests {
    func withStubbedDependencies<T>(_ operation: () throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
            defer { InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository }
            return try operation()
        }
    }

    func singleTokens(in content: TransactionDetailsViewModel.Content) -> TransactionDetailsTokensViewData.Single? {
        guard
            case .generic(let data) = content,
            case .single(let single) = data.tokens?.content
        else {
            return nil
        }

        return single
    }

    func makeDetails(
        status: TransactionRecord.TransactionStatus
    ) -> (header: TransactionDetailsHeaderViewData, content: TransactionDetailsViewModel.Content) {
        let blockchain = Self.ethereum
        let record = TransactionRecord(
            hash: "0xFailedSwap",
            index: 0,
            source: .single(.init(address: Self.walletAddress, amount: 0)),
            destination: .single(.init(address: .contract(Self.contractAddress), amount: 0)),
            fee: Fee(Amount(with: blockchain, value: 0.00003936)),
            status: status,
            isOutgoing: true,
            type: .contractMethodName(name: nil),
            date: Date(),
            tokenTransfers: [],
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
            interactionAddress: transaction.interactionAddress,
            subtitleOwner: transaction.subtitleOwner
        )

        return TransactionDetailsFactory.reduce(
            transaction: transaction,
            record: record,
            cryptoAmount: mapper.displayedAmountValue(from: record),
            context: context,
            addContactHelper: addContactHelper
        )
    }
}
