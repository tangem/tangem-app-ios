//
//  TransactionDetailsStakingContentTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
import TangemLocalization
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("TransactionDetailsFactory staking content")
    final class TransactionDetailsStakingContentTests {
        private static let blockchain = Blockchain.ethereum(testnet: false)
        private static let validator = "0x1111111111111111111111111111111111111111"

        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        @Test(
            "Masks the network fee when balances are hidden",
            arguments: [
                TransactionRecord.TransactionType.StakingTransactionType.stake,
                .unstake,
                .withdraw,
                .claimRewards,
                .restake,
                .vote,
            ]
        )
        func networkFeeIsSensitive(stakingType: TransactionRecord.TransactionType.StakingTransactionType) async throws {
            let rows = try await withStubbedDependencies {
                try #require(makeContent(stakingType: stakingType)?.info?.rows)
            }
            let feeRow = try #require(rows.first { $0.id == "networkFee" })

            guard case .sensitiveText = feeRow.content else {
                Issue.record("Expected the network fee to be sensitive, got \(feeRow.content)")
                return
            }
        }

        @Test("Copies the unresolved validator address from its row")
        func validatorAddressIsCopyable() async throws {
            let rows = try await withStubbedDependencies {
                try #require(makeContent(stakingType: .withdraw)?.info?.rows)
            }
            let validatorRow = try #require(rows.first { $0.id == "validator" })

            guard case .address(let address, let copyAction) = validatorRow.content else {
                Issue.record("Expected the validator row to show its address, got \(validatorRow.content)")
                return
            }

            #expect(address == Self.validator)
            #expect(copyAction == .copy(value: Self.validator, toast: Localization.walletNotificationAddressCopied, kind: .address))
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionDetailsStakingContentTests {
    func withStubbedDependencies<T>(_ operation: () throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
            defer { InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository }
            return try operation()
        }
    }

    func makeContent(stakingType: TransactionRecord.TransactionType.StakingTransactionType) -> TransactionDetailsGenericOperationViewData? {
        let record = TransactionRecord(
            hash: "0xstaking",
            index: 0,
            source: .single(.init(address: "0xtestaddress", amount: 1)),
            destination: .single(.init(address: .user(Self.validator), amount: 1)),
            fee: Fee(Amount(with: Self.blockchain, value: 0.001)),
            status: .confirmed,
            isOutgoing: true,
            type: .staking(type: stakingType, target: Self.validator),
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
            currencySymbol: "ETH",
            blockchain: Self.blockchain,
            addressesProvider: walletModel,
            showSign: true,
            isToken: false,
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
