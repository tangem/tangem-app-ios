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

    @Test("A withdrawal from the own Pay account, an unrecognised contract call, names the Payment account as the sender")
    func payWithdrawalNamesThePaymentAccount() throws {
        let owner = try makePayDepositOwner()

        let counterparty = try #require(
            makeContent(record: makePayWithdrawalRecord(), tangemPayDepositOwners: [owner])?.counterparty
        )

        #expect(counterparty.label == Localization.commonFromAccount)
        #expect(counterparty.actor == .account(name: owner.name, icon: owner.icon))
        #expect(counterparty.copyAction == nil)
    }

    @Test("A contract call whose counterparty is the wallet itself keeps no counterparty row, like an XRP OfferCreate")
    func ownWalletContractCallHasNoCounterparty() {
        let record = TransactionRecord(
            hash: "0xoffer",
            index: 0,
            source: .single(.init(address: "0xtestaddress", amount: 0)),
            destination: .single(.init(address: .user("0xtestaddress"), amount: 0)),
            fee: Fee(Amount(with: Self.blockchain, value: 1)),
            status: .confirmed,
            isOutgoing: true,
            type: .contractMethodName(name: "OfferCreate"),
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
        let transaction = TransactionViewModel(
            hash: record.hash,
            index: record.index,
            interactionAddress: .user("0xtestaddress"),
            timeFormatted: nil,
            amount: "0",
            value: "0",
            currencyCode: "USDC",
            isOutgoing: true,
            transactionType: .operation(name: "OfferCreate"),
            status: .confirmed,
            isFromYieldContract: false,
            subtitleOwner: .accountInCurrentWallet(
                name: "Main account",
                icon: AccountModelUtils.UI.iconViewData(icon: AccountModel.StandaloneIcon.collectibles.erased, accountName: "Main account")
            ),
            isTangemPayCounterparty: false
        )

        let content = makeContent(record: record, transaction: transaction)

        #expect(content?.counterparty == nil)
    }

    @Test("A contract call from an outside address keeps no counterparty row")
    func outsideContractCallHasNoCounterparty() {
        let content = makeContent(record: makePayWithdrawalRecord(), tangemPayDepositOwners: [])

        #expect(content?.counterparty == nil)
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
    static let payDepositAddress = "0x37960c48ebdcf1007d242db9fd29a86527e389b4"

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

        return makeContent(record: record, tangemPayDepositOwners: nil)
    }

    func makeContent(
        record: TransactionRecord,
        tangemPayDepositOwners: [TangemPayDepositOwner]?
    ) -> TransactionDetailsGenericOperationViewData? {
        let userWalletInfo = makeUserWalletInfo()
        let walletModel = CommonWalletModel.previewWalletModel(history: [record])
        let context = TransactionDetailsContext(walletModel: walletModel, userWalletInfo: userWalletInfo, isAccountsMode: false)
        let mapper = TransactionHistoryMapper(
            currencySymbol: "USDC",
            blockchain: Self.blockchain,
            addressesProvider: walletModel,
            showSign: true,
            isToken: true,
            stakingNetwork: nil
        )
        let subtitleOwnerResolver = tangemPayDepositOwners.map { owners in
            SubtitleOwnerResolver(
                blockchain: Self.blockchain,
                currentUserWalletId: userWalletInfo.id,
                isAccountsMode: false,
                contacts: [],
                tangemPayDepositOwners: owners
            )
        }
        let transaction = mapper.mapTransactionViewModel(record, subtitleOwnerResolver: subtitleOwnerResolver)
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

    func makeContent(record: TransactionRecord, transaction: TransactionViewModel) -> TransactionDetailsGenericOperationViewData? {
        let walletModel = CommonWalletModel.previewWalletModel(history: [record])
        let context = TransactionDetailsContext(walletModel: walletModel, userWalletInfo: makeUserWalletInfo(), isAccountsMode: false)
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

    func makePayWithdrawalRecord() -> TransactionRecord {
        TransactionRecord(
            hash: "0xwithdrawal",
            index: 0,
            source: .single(.init(address: Self.payDepositAddress, amount: 2)),
            destination: .single(.init(address: .user("0xtestaddress"), amount: 2)),
            fee: Fee(Amount(with: Self.blockchain, value: 1)),
            status: .confirmed,
            isOutgoing: false,
            type: .contractMethodIdentifier(id: "0x4b268241"),
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
    }

    func makePayDepositOwner() throws -> TangemPayDepositOwner {
        let networks = try makeTangemPayNetworks(
            """
            [
              {
                "name": "polygon-pos",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "\(Self.payDepositAddress)",
                "tokens": [{ "token": "USDC", "tokenContractAddress": "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359" }]
              }
            ]
            """
        )

        return TangemPayDepositOwner(
            userWalletId: makeUserWalletInfo().id,
            name: "Payment account",
            icon: AccountModelUtils.UI.iconViewData(icon: AccountModel.StandaloneIcon.tangemPay.erased, accountName: "Payment account"),
            entries: TangemPayAccountTokensResolver.makeEntries(from: networks)
        )
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
