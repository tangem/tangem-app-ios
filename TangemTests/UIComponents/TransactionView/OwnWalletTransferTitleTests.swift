//
//  OwnWalletTransferTitleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
import TangemLocalization
@testable import Tangem

@Suite("Own-wallet transfer title ([REDACTED_INFO])")
struct OwnWalletTransferTitleTests {
    @Test("Transfer to an own wallet is titled Transferred regardless of direction")
    func ownWalletTransferIsTransferred() {
        #expect(title(owner: .wallet(name: "My Wallet", imageProvider: nil, thumbnailType: nil), isOutgoing: true, status: .confirmed) == Localization.commonTransferred)
        #expect(title(owner: .wallet(name: "My Wallet", imageProvider: nil, thumbnailType: nil), isOutgoing: false, status: .confirmed) == Localization.commonTransferred)
    }

    @Test("Own-wallet transfer follows status for in-progress and failed")
    func ownWalletTransferStatuses() {
        #expect(
            title(owner: .wallet(name: "My Wallet", imageProvider: nil, thumbnailType: nil), isOutgoing: true, status: .inProgress)
                == Localization.transactionHistoryStatusTransferring
        )
        #expect(
            title(owner: .wallet(name: "My Wallet", imageProvider: nil, thumbnailType: nil), isOutgoing: true, status: .failed)
                == Localization.transactionHistoryStatusTransferFailed
        )
    }

    @Test("Transfer to an external address stays Send/Received")
    func externalTransferStaysDirectional() {
        let external = TransactionViewModel.SubtitleOwner.unresolved(short: "0xAB…CD", fullAddress: "0xABCD", blockiesImage: nil)
        #expect(title(owner: external, isOutgoing: true, status: .confirmed) == Localization.commonSent)
        #expect(title(owner: external, isOutgoing: false, status: .confirmed) == Localization.commonReceived)
        #expect(title(owner: nil, isOutgoing: true, status: .confirmed) == Localization.commonSent)
        #expect(title(owner: nil, isOutgoing: false, status: .confirmed) == Localization.commonReceived)
    }

    @Test("Transfer to an address book contact stays Send/Received")
    func addressBookContactTransferStaysDirectional() {
        let contact = TransactionViewModel.SubtitleOwner.contact(
            name: "Danielle",
            icon: AddressBookContactNameIconViewData(letter: "D", color: .blue),
            fullAddress: "0xABCD"
        )
        #expect(title(owner: contact, isOutgoing: true, status: .confirmed) == Localization.commonSent)
        #expect(title(owner: contact, isOutgoing: false, status: .confirmed) == Localization.commonReceived)
    }

    @Test("A contract call to or from the own Tangem Pay deposit address is titled Transferred")
    func payOperationIsTransferred() {
        let paymentAccount = TransactionViewModel.SubtitleOwner.accountInCurrentWallet(
            name: "Payment account",
            icon: AccountModelUtils.UI.iconViewData(icon: AccountModel.StandaloneIcon.tangemPay.erased, accountName: "Payment account")
        )

        #expect(
            title(owner: paymentAccount, isOutgoing: false, status: .confirmed, transactionType: .operation(name: "Operation"), isTangemPayCounterparty: true)
                == Localization.commonTransferred
        )
        #expect(
            title(owner: paymentAccount, isOutgoing: true, status: .confirmed, transactionType: .unknownOperation, isTangemPayCounterparty: true)
                == Localization.commonTransferred
        )
        #expect(
            title(owner: paymentAccount, isOutgoing: false, status: .inProgress, transactionType: .operation(name: "Operation"), isTangemPayCounterparty: true)
                == Localization.transactionHistoryStatusTransferring
        )
    }

    @Test("A contract call whose counterparty is the wallet itself keeps its operation name, like an XRP OfferCreate")
    func ownWalletOperationKeepsItsName() {
        let mainAccount = TransactionViewModel.SubtitleOwner.accountInCurrentWallet(
            name: "Main account",
            icon: AccountModelUtils.UI.iconViewData(icon: AccountModel.StandaloneIcon.collectibles.erased, accountName: "Main account")
        )

        #expect(
            title(owner: mainAccount, isOutgoing: true, status: .confirmed, transactionType: .operation(name: "OfferCreate"), isTangemPayCounterparty: false)
                == "Transfer"
        )
    }

    @Test("A contract call with an outside address keeps its operation name")
    func externalOperationKeepsItsName() {
        let external = TransactionViewModel.SubtitleOwner.unresolved(short: "0xAB…CD", fullAddress: "0xABCD", blockiesImage: nil)

        #expect(
            title(owner: external, isOutgoing: false, status: .confirmed, transactionType: .operation(name: "Operation"), isTangemPayCounterparty: false)
                == "Transfer"
        )
        #expect(title(owner: nil, isOutgoing: true, status: .confirmed, transactionType: .unknownOperation, isTangemPayCounterparty: false) == "Transfer")
    }

    private func title(
        owner: TransactionViewModel.SubtitleOwner?,
        isOutgoing: Bool,
        status: TransactionViewModel.Status
    ) -> String {
        title(owner: owner, isOutgoing: isOutgoing, status: status, transactionType: .transfer, isTangemPayCounterparty: false)
    }

    private func title(
        owner: TransactionViewModel.SubtitleOwner?,
        isOutgoing: Bool,
        status: TransactionViewModel.Status,
        transactionType: TransactionViewModel.TransactionType,
        isTangemPayCounterparty: Bool
    ) -> String {
        TransactionDisplayModel.make(
            transactionType: transactionType,
            status: status,
            isOutgoing: isOutgoing,
            isFromYieldContract: false,
            legacyName: "Transfer",
            addressDestination: nil,
            subtitleOwner: owner,
            isTangemPayCounterparty: isTangemPayCounterparty,
            expressSubtitle: nil
        ).title.fullText
    }
}
