//
//  TransactionHistoryMapperYieldTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemLocalization
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransactionHistoryMapper Yield Mode presentation ([REDACTED_INFO])")
struct TransactionHistoryMapperYieldTests {
    // MARK: - Chip vs row

    @Test("Enabling and disabling Yield Mode stays a chip, for both the token and the coin variant")
    func enableDisableAreChips() {
        #expect(makeSUT(isToken: true).mapTransactionViewModel(makeYieldRecord(method: "yieldEnter")).display.style == .chip)
        #expect(makeSUT(isToken: false).mapTransactionViewModel(makeYieldRecord(method: "yieldEnter")).display.style == .chip)
        #expect(makeSUT(isToken: true).mapTransactionViewModel(makeYieldRecord(method: "yieldWithdraw")).display.style == .chip)
        #expect(makeSUT(isToken: false).mapTransactionViewModel(makeYieldRecord(method: "yieldWithdraw")).display.style == .chip)
    }

    @Test("Supply and Withdraw are chips")
    func supplyAndWithdrawAreChips() {
        #expect(makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup")).display.style == .chip)
        #expect(makeSUT().mapTransactionViewModel(makeWithdrawRecord()).display.style == .chip)
    }

    @Test("Contract lifecycle calls are full rows")
    func contractLifecycleCallsAreRows() {
        #expect(makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldDeploy")).display.style == .row)
        #expect(makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldInit")).display.style == .row)
        #expect(makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldReactivate")).display.style == .row)
    }

    // MARK: - Amount and subtitle suppression

    @Test("Enable and disable chips carry neither an amount nor a subtitle")
    func enableDisableChipsAreLabelOnly() {
        for isToken in [true, false] {
            for method in ["yieldEnter", "yieldWithdraw"] {
                let viewModel = makeSUT(isToken: isToken).mapTransactionViewModel(makeYieldRecord(method: method))

                #expect(viewModel.amount.displayValue == nil)
                #expect(viewModel.display.subtitle == nil)
            }
        }
    }

    @Test("The legacy row keeps showing the amount of the coin-variant enable and disable")
    func legacyAmountVisibilityIsUntouched() {
        #expect(makeSUT(isToken: false).mapTransactionViewModel(makeYieldRecord(method: "yieldEnter")).amount.formattedAmount != nil)
        #expect(makeSUT(isToken: true).mapTransactionViewModel(makeYieldRecord(method: "yieldEnter")).amount.formattedAmount == nil)
    }

    @Test("The Supply and Withdraw chips carry no amount")
    func supplyAndWithdrawChipsHaveNoAmount() {
        #expect(makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup")).amount.displayValue == nil)
        #expect(makeSUT().mapTransactionViewModel(makeWithdrawRecord()).amount.displayValue == nil)
    }

    // MARK: - Type-driven sign

    @Test("Supply is signed `+` even though the funds leave the wallet")
    func supplySignIsPositive() {
        let viewModel = makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup", isOutgoing: true))

        #expect(viewModel.amount.value.hasPrefix(AppConstants.plusSign))
    }

    @Test("Withdraw is signed `−` even though the funds come back to the wallet")
    func withdrawSignIsNegative() {
        let viewModel = makeSUT().mapTransactionViewModel(makeWithdrawRecord())

        #expect(viewModel.amount.value.hasPrefix(AppConstants.minusSign))
    }

    @Test("The coin variants of enable and disable stay unsigned, like the token ones")
    func coinVariantsAreUnsigned() {
        let sut = makeSUT(isToken: false)

        for method in ["yieldEnter", "yieldWithdraw"] {
            let amount = sut.mapTransactionViewModel(makeYieldRecord(method: method, isOutgoing: true)).amount

            #expect(!amount.amount.hasPrefix(AppConstants.minusSign))
            #expect(!amount.amountWithCurrencyCode.hasPrefix(AppConstants.minusSign))
        }
    }

    @Test("The sign the redesign invents never reaches the legacy amount string")
    func legacyAmountStaysUnsigned() {
        #expect(!makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup")).amount.amount.hasPrefix(AppConstants.plusSign))
        #expect(!makeSUT().mapTransactionViewModel(makeWithdrawRecord()).amount.amount.hasPrefix(AppConstants.minusSign))
    }

    @Test("A failed Supply drops the sign, matching the strikethrough treatment of every other type")
    func failedSupplyIsUnsigned() {
        let viewModel = makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup", status: .failed))

        #expect(!viewModel.amount.value.hasPrefix(AppConstants.plusSign))
    }

    // MARK: - Provider subtitle

    @Test("Supply names the provider it sends to, Withdraw the one it comes back from")
    func supplyAndWithdrawNameTheProvider() {
        #expect(makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup")).display.subtitle == .provider(direction: .outgoing))
        #expect(makeSUT().mapTransactionViewModel(makeWithdrawRecord()).display.subtitle == .provider(direction: .incoming))
    }

    @Test("A transfer-like yieldSend keeps its counterparty subtitle instead of the provider")
    func transferLikeSendKeepsCounterparty() {
        let record = makeRecord(type: .contractMethodName(name: "yieldSend"), isOutgoing: true)

        let subtitle = makeSUT().mapTransactionViewModel(record, subtitleOwnerResolver: makeResolver()).display.subtitle

        guard case .owner = subtitle else {
            Issue.record("Expected a counterparty subtitle, got \(String(describing: subtitle))")
            return
        }
    }

    // MARK: - Status-aware titles

    @Test("Withdraw follows its status")
    func withdrawTitleFollowsStatus() {
        #expect(title(makeWithdrawRecord(status: .unconfirmed)) == Localization.commonWithdrawing)
        #expect(title(makeWithdrawRecord(status: .confirmed)) == Localization.transactionHistoryWithdrawn)
        #expect(title(makeWithdrawRecord(status: .failed)) == Localization.transactionHistoryStatusWithdrawFailed)
    }

    @Test("Supply follows its status")
    func supplyTitleFollowsStatus() {
        let make = { (status: TransactionRecord.TransactionStatus) in
            title(makeYieldRecord(method: "yieldTopup", status: status))
        }

        #expect(make(.unconfirmed) == Localization.commonSupplying)
        #expect(make(.confirmed) == Localization.transactionHistorySupplied)
        #expect(make(.failed) == Localization.transactionHistoryStatusSupplyFailed)
    }

    @Test("Enabling Yield Mode follows its status, for both the token and the coin variant")
    func enableTitleFollowsStatus() {
        for isToken in [true, false] {
            let sut = makeSUT(isToken: isToken)
            let make = { (status: TransactionRecord.TransactionStatus) in
                sut.mapTransactionViewModel(makeYieldRecord(method: "yieldEnter", status: status)).display.title
            }

            #expect(make(.unconfirmed) == .plain(Localization.transactionHistoryEnablingYieldMode))
            #expect(make(.confirmed) == .emphasizedSuffix(prefix: "\(Localization.commonYieldModeInline) ", emphasized: Localization.commonEnabled))
            #expect(make(.failed) == .plain(Localization.transactionHistoryStatusEnablingYieldModeFailed))
        }
    }

    @Test("Disabling Yield Mode follows its status, for both the token and the coin variant")
    func disableTitleFollowsStatus() {
        for isToken in [true, false] {
            let sut = makeSUT(isToken: isToken)
            let make = { (status: TransactionRecord.TransactionStatus) in
                sut.mapTransactionViewModel(makeYieldRecord(method: "yieldWithdraw", status: status)).display.title
            }

            #expect(make(.unconfirmed) == .plain(Localization.transactionHistoryDisablingYieldMode))
            #expect(make(.confirmed) == .emphasizedSuffix(prefix: "\(Localization.commonYieldModeInline) ", emphasized: Localization.commonDisabled))
            #expect(make(.failed) == .plain(Localization.transactionHistoryStatusDisablingYieldModeFailed))
        }
    }

    // MARK: - Ticker position

    @Test("The details-sheet amount puts the ticker after the number regardless of locale")
    func sheetAmountTickerFollowsTheNumber() {
        let viewModel = makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldEnter"))

        #expect(viewModel.amount.amountWithCurrencyCode == "2.00\u{a0}ETH")
    }

    @Test("The details sheet signs Supply and Withdraw the same way the row does")
    func sheetAmountCarriesTheTypeDrivenSign() {
        let supply = makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup"))
        let withdraw = makeSUT().mapTransactionViewModel(makeWithdrawRecord())

        #expect(supply.amount.amountWithCurrencyCode == "+\u{a0}2.00\u{a0}ETH")
        #expect(withdraw.amount.amountWithCurrencyCode == "−\u{a0}2.00\u{a0}ETH")
    }

    // MARK: - Approve

    @Test("An approve names its spender, not the token contract it was sent to")
    func approveSubtitleNamesTheSpender() {
        let record = makeRecord(
            type: .approve(TransactionRecord.TransactionType.Approve(spender: "0xSpender", symbol: "USDT", allowance: .limited(100))),
            isOutgoing: true
        )

        let viewModel = makeSUT().mapTransactionViewModel(record, subtitleOwnerResolver: makeResolver())

        guard case .unresolved(_, let fullAddress, _) = viewModel.subtitleOwner else {
            Issue.record("Expected an unresolved counterparty, got \(String(describing: viewModel.subtitleOwner))")
            return
        }

        #expect(fullAddress == "0xSpender")
    }

    @Test("The legacy interaction address keeps pointing at the token contract")
    func approveInteractionAddressIsUntouched() {
        let record = makeRecord(
            type: .approve(TransactionRecord.TransactionType.Approve(spender: "0xSpender", symbol: "USDT", allowance: .limited(100))),
            isOutgoing: true
        )

        let viewModel = makeSUT().mapTransactionViewModel(record, subtitleOwnerResolver: makeResolver())

        #expect(viewModel.interactionAddress == .contract("0xTokenContract"))
    }

    @Test("A contract call that merely looks like an approve falls back to the destination")
    func undecodedApproveFallsBackToDestination() {
        let record = makeRecord(type: .contractMethodName(name: "approve"), isOutgoing: true)

        let viewModel = makeSUT().mapTransactionViewModel(record, subtitleOwnerResolver: makeResolver())

        guard case .unresolved(_, let fullAddress, _) = viewModel.subtitleOwner else {
            Issue.record("Expected an unresolved counterparty, got \(String(describing: viewModel.subtitleOwner))")
            return
        }

        #expect(fullAddress == "0xTokenContract")
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperYieldTests {
    func makeSUT(isToken: Bool = true) -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "ETH",
            blockchain: .ethereum(testnet: false),
            addressesProvider: StubTransactionHistoryAddressesProvider(walletAddresses: ["0xSource"]),
            showSign: true,
            isToken: isToken,
            stakingNetwork: .ethereum
        )
    }

    func makeResolver() -> SubtitleOwnerResolver {
        SubtitleOwnerResolver(
            blockchain: .ethereum(testnet: false),
            currentUserWalletId: UserWalletId(value: Data()),
            isAccountsMode: false,
            contacts: []
        )
    }

    func makeYieldRecord(
        method: String,
        isOutgoing: Bool = true,
        status: TransactionRecord.TransactionStatus = .confirmed
    ) -> TransactionRecord {
        makeRecord(type: .contractMethodName(name: method), isOutgoing: isOutgoing, status: status)
    }

    func title(_ record: TransactionRecord) -> String {
        makeSUT().mapTransactionViewModel(record).display.title.fullText
    }

    /// `yieldSend` from the Aave contract — the Withdraw leg, which arrives as an incoming transfer.
    func makeWithdrawRecord(status: TransactionRecord.TransactionStatus = .confirmed) -> TransactionRecord {
        makeRecord(
            type: .contractMethodName(name: "yieldSend"),
            isOutgoing: false,
            status: status,
            isFromYieldContract: true
        )
    }

    func makeRecord(
        type: TransactionRecord.TransactionType,
        isOutgoing: Bool,
        status: TransactionRecord.TransactionStatus = .confirmed,
        isFromYieldContract: Bool = false
    ) -> TransactionRecord {
        TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(TransactionRecord.Source(address: isOutgoing ? "0xSource" : "0xTokenContract", amount: 2)),
            destination: .single(TransactionRecord.Destination(address: .contract(isOutgoing ? "0xTokenContract" : "0xSource"), amount: 2)),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18)),
            status: status,
            isOutgoing: isOutgoing,
            type: type,
            date: Date(),
            tokenTransfers: [],
            isFromYieldContract: isFromYieldContract,
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubTransactionHistoryAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
