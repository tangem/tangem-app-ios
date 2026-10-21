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
        #expect(makeSUT(isToken: true).mapTransactionViewModel(makeYieldRecord(method: "yieldEnter")).display.style == .chip(.plain))
        #expect(makeSUT(isToken: false).mapTransactionViewModel(makeYieldRecord(method: "yieldEnter")).display.style == .chip(.plain))
        #expect(makeSUT(isToken: true).mapTransactionViewModel(makeYieldRecord(method: "yieldWithdraw")).display.style == .chip(.plain))
        #expect(makeSUT(isToken: false).mapTransactionViewModel(makeYieldRecord(method: "yieldWithdraw")).display.style == .chip(.plain))
    }

    @Test("Supply and Withdraw are chips")
    func supplyAndWithdrawAreChips() {
        #expect(makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup")).display.style == .chip(.plain))
        #expect(makeSUT().mapTransactionViewModel(makeWithdrawRecord()).display.style == .chip(.plain))
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

    @Test("Supply is signed `−`: the funds leave the wallet")
    func supplySignIsNegative() {
        let viewModel = makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup", isOutgoing: true))

        #expect(viewModel.amount.value?.hasPrefix(AppConstants.minusSign) == true)
    }

    @Test("Withdraw is signed `+`: the funds come back to the wallet")
    func withdrawSignIsPositive() {
        let viewModel = makeSUT().mapTransactionViewModel(makeWithdrawRecord())

        #expect(viewModel.amount.value?.hasPrefix(AppConstants.plusSign) == true)
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
        for record in [makeYieldRecord(method: "yieldTopup"), makeWithdrawRecord()] {
            let amount = makeSUT().mapTransactionViewModel(record).amount.amount

            #expect(!amount.hasPrefix(AppConstants.minusSign))
            #expect(!amount.hasPrefix(AppConstants.plusSign))
        }
    }

    @Test("A failed Supply drops the sign, matching the strikethrough treatment of every other type")
    func failedSupplyIsUnsigned() {
        let viewModel = makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup", status: .failed))

        #expect(viewModel.amount.value?.hasPrefix(AppConstants.minusSign) == false)
        #expect(viewModel.amount.value?.hasPrefix(AppConstants.plusSign) == false)
    }

    // MARK: - Incentive claim

    @Test("The claim is a chip on the coin screen and a full row on the reward token")
    func claimStyleDependsOnTheScreen() {
        #expect(makeSUT(isToken: false).mapTransactionViewModel(makeClaimRecord()).display.style == .chip(.success))
        #expect(makeSUT(isToken: true).mapTransactionViewModel(makeClaimRecord()).display.style == .row)
    }

    @Test("Only a settled claim goes green; in flight and failed keep the treatment every chip shares")
    func claimCoinChipStyleFollowsStatus() {
        let sut = makeSUT(isToken: false)
        let make = { (status: TransactionRecord.TransactionStatus) in
            sut.mapTransactionViewModel(makeClaimRecord(status: status)).display.style
        }

        #expect(make(.unconfirmed) == .chip(.progress))
        #expect(make(.confirmed) == .chip(.success))
        #expect(make(.failed) == .chip(.error))
    }

    @Test("The coin chip states the claim and nothing else, as no reward reaches that balance")
    func claimCoinChipIsLabelOnly() {
        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(makeClaimRecord())

        #expect(viewModel.amount.displayValue == nil)
        #expect(viewModel.display.subtitle == nil)
    }

    @Test("The reward row keeps its amount and names Merkl instead of the module address it came from")
    func claimRowKeepsAmountAndNamesTheProvider() {
        let viewModel = makeSUT(isToken: true)
            .mapTransactionViewModel(makeClaimRecord(), subtitleOwnerResolver: makeResolver())

        #expect(viewModel.amount.displayValue != nil)
        #expect(viewModel.display.subtitle == .provider(direction: .incoming, provider: .merkl))
    }

    @Test("The coin chip names the claim and follows its status")
    func claimCoinTitleFollowsStatus() {
        let sut = makeSUT(isToken: false)
        let make = { (status: TransactionRecord.TransactionStatus) in
            sut.mapTransactionViewModel(makeClaimRecord(status: status)).display.title
        }

        #expect(make(.unconfirmed) == .plain(Localization.transactionHistoryClaimingIncentiveRewards))
        #expect(make(.confirmed) == .plain(Localization.transactionHistoryIncentiveRewardsClaimed))
        #expect(make(.failed) == .plain(Localization.transactionHistoryStatusIncentiveRewardsClaimFailed))
    }

    @Test("The reward row reads as the incoming transfer it is")
    func claimRowFollowsItsDirection() {
        let sut = makeSUT(isToken: true)
        let make = { (status: TransactionRecord.TransactionStatus) in
            sut.mapTransactionViewModel(makeClaimRecord(status: status)).display.title
        }

        #expect(make(.unconfirmed) == .plain(Localization.commonReceiving))
        #expect(make(.confirmed) == .plain(Localization.commonReceived))
        #expect(make(.failed) == .plain(Localization.transactionHistoryStatusReceiveFailed))
    }

    // MARK: - Provider subtitle

    @Test("Supply names the provider it sends to, Withdraw the one it comes back from")
    func supplyAndWithdrawNameTheProvider() {
        #expect(makeSUT().mapTransactionViewModel(makeYieldRecord(method: "yieldTopup")).display.subtitle == .provider(direction: .outgoing, provider: .aave))
        #expect(makeSUT().mapTransactionViewModel(makeWithdrawRecord()).display.subtitle == .provider(direction: .incoming, provider: .aave))
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

    // MARK: - Gasless send

    @Test("An Aave payout of a batched gasless send is a Withdraw, like the one of a plain send")
    func gaslessPayoutFromAaveIsWithdraw() {
        let record = makeRecord(type: .contractMethodName(name: "gaslessTransaction"), isOutgoing: false, isFromYieldContract: true)

        let viewModel = makeSUT().mapTransactionViewModel(record)

        #expect(viewModel.display.title.fullText == Localization.transactionHistoryWithdrawn)
        #expect(viewModel.display.subtitle == .provider(direction: .incoming, provider: .aave))
        #expect(viewModel.amount.value?.hasPrefix(AppConstants.plusSign) == true)
    }

    @Test("A gasless transfer that does not come from Aave is still received")
    func gaslessTransferFromElsewhereIsReceived() {
        let record = makeRecord(type: .contractMethodName(name: "gaslessTransaction"), isOutgoing: false)

        #expect(title(record) == Localization.commonReceived)
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

        #expect(supply.amount.amountWithCurrencyCode == "−\u{2009}2.00\u{a0}ETH")
        #expect(withdraw.amount.amountWithCurrencyCode == "+\u{2009}2.00\u{a0}ETH")
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

    func makeClaimRecord(status: TransactionRecord.TransactionStatus = .confirmed) -> TransactionRecord {
        makeRecord(type: .contractMethodName(name: "yieldClaim"), isOutgoing: false, status: status)
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
