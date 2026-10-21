//
//  TransactionDetailsSendContentTests.swift
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

/// A plain transfer never looks anything up in the aux data repository, so the suite leaves it alone.
@Suite("TransactionDetailsFactory send and receive content")
struct TransactionDetailsSendContentTests {
    private static let blockchain = Blockchain.polygon(testnet: false)

    /// `BalanceFormatter.formatCryptoBalance` puts the ticker first in `en_US` (`USDC 0.10`), which the sheet
    /// never wants.
    @Test(
        "Shows the amount with the ticker after the number",
        arguments: [
            (isOutgoing: true, expected: "−\u{2009}0.10\u{a0}USDC"),
            (isOutgoing: false, expected: "+\u{2009}0.10\u{a0}USDC"),
        ]
    )
    func amountPutsTickerAfterNumber(isOutgoing: Bool, expected: String) throws {
        let single = try #require(makeContent(type: .transfer, isOutgoing: isOutgoing, status: .confirmed)?.tokens?.single)

        #expect(single.amountText == expected)
    }

    @Test("Drops the sign of a failed transfer, like the history row does")
    func failedTransferHasNoSign() throws {
        let single = try #require(makeContent(type: .transfer, isOutgoing: true, status: .failed)?.tokens?.single)

        #expect(single.amountText == "0.10\u{a0}USDC")
        #expect(single.isAmountStrikethrough)
    }

    @Test(
        "Names the counterparty of a Yield-mode transfer, like a plain transfer",
        arguments: [
            (isOutgoing: true, label: Localization.sendRecipient, address: "0xrecipient"),
            (isOutgoing: false, label: Localization.commonFromAddress, address: "0xsender"),
        ]
    )
    func yieldModeTransferShowsCounterparty(isOutgoing: Bool, label: String, address: String) throws {
        let content = makeContent(type: .contractMethodName(name: "yieldSend"), isOutgoing: isOutgoing, status: .confirmed)
        let counterparty = try #require(content?.counterparty)

        #expect(counterparty.label == label)
        #expect(counterparty.actor.displayName == address)
    }
}

// MARK: - Helpers

private extension TransactionDetailsSendContentTests {
    func makeContent(
        type: TransactionRecord.TransactionType,
        isOutgoing: Bool,
        status: TransactionRecord.TransactionStatus
    ) -> TransactionDetailsGenericOperationViewData? {
        let record = TransactionRecord(
            hash: "0xsent",
            index: 0,
            source: .single(.init(address: isOutgoing ? "0xtestaddress" : "0xsender", amount: 0.1)),
            destination: .single(.init(address: .user(isOutgoing ? "0xrecipient" : "0xtestaddress"), amount: 0.1)),
            fee: Fee(Amount(with: Self.blockchain, value: 0.01)),
            status: status,
            isOutgoing: isOutgoing,
            type: type,
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
        let walletModel = CommonWalletModel.previewWalletModel(history: [record])
        let context = TransactionDetailsContext(walletModel: walletModel, userWalletInfo: makeUserWalletInfo(), isAccountsMode: false)
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
            cryptoAmount: 0.1,
            context: context,
            addContactHelper: addContactHelper
        ).content

        guard case .generic(let data) = content else {
            return nil
        }

        return data
    }

    func makeUserWalletInfo() -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }
}

private extension TransactionDetailsTokensViewData {
    var single: Single? {
        guard case .single(let single) = content else {
            return nil
        }

        return single
    }
}
