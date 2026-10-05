//
//  TransactionDetailsYieldFeeTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("TransactionDetailsFactory network fee of a withdrawal from Aave")
    final class TransactionDetailsYieldFeeTests {
        private static let blockchain = Blockchain.polygon(testnet: false)
        private static let walletAddress = "0xwallet"
        private static let aToken = "0xA4D94019934D8333Ef880ABFFbF2FDd611C762BD"

        private let previousAuxDataRepository: TransactionHistoryAuxDataRepository
        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        init() {
            previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
        }

        deinit {
            InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository
        }

        @Test("The wallet's own Yield-mode send shows the fee it paid on the withdrawal it made")
        func aWithdrawalTheWalletSentShowsItsFee() throws {
            let content = try #require(makeContent(methodName: "yieldSend"))

            #expect(content.info?.rows.contains { $0.id == "networkFee" } == true)
        }

        @Test("A gasless send shows no fee on the withdrawal: its gas was paid by the relayer")
        func aWithdrawalTheRelayerSentShowsNoFee() throws {
            let content = try #require(makeContent(methodName: "gaslessTransaction"))

            #expect(content.info?.rows.contains { $0.id == "networkFee" } != true)
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionDetailsYieldFeeTests {
    func makeContent(methodName: String) -> TransactionDetailsGenericOperationViewData? {
        let record = TransactionRecord(
            hash: "0xwithdrawal",
            index: 0,
            source: .single(.init(address: Self.aToken, amount: 0.03)),
            destination: .single(.init(address: .user(Self.walletAddress), amount: 0.03)),
            fee: Fee(Amount(with: Self.blockchain, value: 0.15)),
            status: .confirmed,
            isOutgoing: false,
            type: .contractMethodName(name: methodName),
            date: Date(),
            tokenTransfers: [],
            isFromYieldContract: true,
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
