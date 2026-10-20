//
//  TransactionDetailsPreviewFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemExpress
import TangemAccounts
import TangemAssets
import TangemUI

@MainActor
enum TransactionDetailsPreviewFactory {
    // MARK: - Send / Receive

    static func sent() -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xsent",
            type: .transfer,
            isOutgoing: true,
            source: .init(address: walletAddress, amount: 0.35),
            destination: .init(address: .user(counterpartyAddress), amount: 0.35)
        ))
    }

    static func received() -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xreceived",
            type: .transfer,
            isOutgoing: false,
            source: .init(address: counterpartyAddress, amount: 0.35),
            destination: .init(address: .user(walletAddress), amount: 0.35)
        ))
    }

    // MARK: - Staking / Approve / Fee / Other (single-operation)

    static func staking() -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xstaked",
            type: .staking(type: .stake, target: validatorAddress),
            isOutgoing: true,
            source: .init(address: walletAddress, amount: 1.0),
            destination: .init(address: .user(validatorAddress), amount: 1.0)
        ))
    }

    static func approve() -> TransactionDetailsViewModel {
        // The allowance reaches the sheet already scaled by the token's decimals, so this is 1 234.5678 USDT rather
        // than a raw integer. The value carries both a grouping separator and a fraction on purpose — a round number
        // would render identically whether or not the amount is formatted at all.
        approve(allowance: .limited(1234.5678))
    }

    static func approveUnlimited() -> TransactionDetailsViewModel {
        approve(allowance: .unlimited)
    }

    private static func approve(allowance: TransactionRecord.TransactionType.Approve.Allowance) -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xapproved",
            type: .approve(.init(spender: spenderAddress, symbol: "USDT", allowance: allowance)),
            isOutgoing: true,
            source: .init(address: walletAddress, amount: 0),
            destination: .init(address: .contract(tokenContractAddress), amount: 0)
        ))
    }

    static func fee() -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xfee",
            type: .transfer,
            isOutgoing: true,
            source: .init(address: walletAddress, amount: 0.000015),
            destination: .init(address: .user(counterpartyAddress), amount: 0.000015)
        ))
    }

    static func other() -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xoperation",
            type: .contractMethodName(name: "Deposit"),
            isOutgoing: true,
            source: .init(address: walletAddress, amount: 0.2),
            destination: .init(address: .contract(spenderAddress), amount: 0.2)
        ))
    }

    // MARK: - Yield

    static func yieldSupplied() -> TransactionDetailsYieldTokensViewData {
        .init(
            provider: .leading(Assets.YieldModule.yieldModuleAaveLogo),
            tokenIconInfo: icon("Tether", color: .green),
            amountText: "1,294.23 USDT",
            caption: "Supplied",
            fiatText: nil,
            isAmountStrikethrough: false
        )
    }

    static func yieldReturned() -> TransactionDetailsYieldTokensViewData {
        .init(
            provider: .trailing(Assets.YieldModule.yieldModuleAaveLogo),
            tokenIconInfo: icon("Tether", color: .green),
            amountText: "1,294.23 USDT",
            caption: "Returned",
            fiatText: nil,
            isAmountStrikethrough: false
        )
    }

    static func yieldEnabled() -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xyieldenter",
            type: .contractMethodName(name: "yieldEnter"),
            isOutgoing: true,
            source: .init(address: walletAddress, amount: 2.5),
            destination: .init(address: .contract(spenderAddress), amount: 2.5)
        ))
    }

    static func yieldDisabled() -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xyieldwithdraw",
            type: .contractMethodName(name: "yieldWithdraw"),
            isOutgoing: false,
            source: .init(address: spenderAddress, amount: 2.5),
            destination: .init(address: .user(walletAddress), amount: 2.5)
        ), token: .tetherMock)
    }

    static func yieldDisabledTransferLeg() -> TransactionDetailsViewModel {
        viewModel(record: onChainRecord(
            hash: "0xyieldsend",
            type: .contractMethodName(name: "yieldSend"),
            isOutgoing: false,
            source: .init(address: spenderAddress, amount: 2.5),
            destination: .init(address: .user(walletAddress), amount: 2.5),
            isFromYieldContract: true
        ), token: .tetherMock)
    }

    // MARK: - Swap

    static func swapInProgress() -> TransactionDetailsViewModel {
        viewModel(record: swapRecord(hash: "0xswapinprogress", status: .exchanging))
    }

    static func swapFinished() -> TransactionDetailsViewModel {
        viewModel(record: swapRecord(hash: "0xswapfinished", status: .finished))
    }

    static func swapFailed() -> TransactionDetailsViewModel {
        viewModel(record: swapRecord(hash: "0xswapfailed", status: .failed))
    }

    // MARK: - Onramp

    static func onrampInProgress() -> TransactionDetailsViewModel {
        viewModel(record: onrampRecord(hash: "0xonrampinprogress", status: .waitingForPayment))
    }

    static func onrampFinished() -> TransactionDetailsViewModel {
        viewModel(record: onrampRecord(hash: "0xonrampfinished", status: .finished))
    }

    static func onrampFailed() -> TransactionDetailsViewModel {
        viewModel(record: onrampRecord(hash: "0xonrampfailed", status: .failed))
    }

    static func onrampExpired() -> TransactionDetailsViewModel {
        viewModel(record: onrampRecord(hash: "0xonrampexpired", status: .expired))
    }

    // MARK: - Principal amount (fee "For sending")

    static func principalAmount() -> TransactionDetailsPrincipalAmountViewData {
        .init(icon: DesignSystem.Icons.ArrowUp.regular24, label: "For sending", amount: "120.03 USDT", tokenIconInfo: icon("Tether", color: .green))
    }

    // MARK: - Tokens block

    static func tokensSingle() -> TransactionDetailsTokensViewData {
        .init(
            icon: .token(icon("Tether", color: .green)),
            caption: nil,
            amountText: "+350.31 USDT",
            fiatText: "$350.31",
            isAmountStrikethrough: false
        )
    }

    /// Failed single operation — the amount is struck through and dimmed.
    static func tokensSingleFailed() -> TransactionDetailsTokensViewData {
        .init(icon: .token(icon("Tether", color: .green)), caption: nil, amountText: "350.31 USDT", fiatText: "$350.31", isAmountStrikethrough: true)
    }

    static func tokensPair() -> TransactionDetailsTokensViewData {
        .init(
            from: .init(direction: .init(label: "From", actor: nil), icon: .token(icon("Tether", color: .green)), amountText: "− 390 USDT", fiatText: "$391.12"),
            to: .init(direction: .init(label: "To", actor: nil), icon: .token(icon("Polygon", color: .purple)), amountText: "~ 1,800.00 POL", fiatText: "$391.12")
        )
    }

    /// Pair with the destination token still resolving — amount hidden, icon shimmering.
    static func tokensPairLoading() -> TransactionDetailsTokensViewData {
        .init(
            from: .init(direction: .init(label: "From", actor: nil), icon: .token(icon("Tether", color: .green)), amountText: "− 390 USDT", fiatText: "$391.12"),
            to: .init(direction: .init(label: "To", actor: nil), icon: .loading, amountText: nil, fiatText: nil)
        )
    }
}

// MARK: - View model builder

private extension TransactionDetailsPreviewFactory {
    static let noopRoutable = NoopTransactionDetailsRoutable()

    static func viewModel(record: TransactionRecord, token: Token? = nil) -> TransactionDetailsViewModel {
        guard let userWalletModel = CommonUserWalletModel.mock else {
            preconditionFailure("CommonUserWalletModel.mock is unavailable in previews")
        }

        return TransactionDetailsViewModel(
            id: record.id,
            walletModel: CommonWalletModel.previewWalletModel(history: [record], token: token),
            userWalletInfo: userWalletModel.userWalletInfo,
            isAccountsMode: false,
            addressBookManager: userWalletModel.addressBookManager,
            addressBookAnalyticsLogger: CommonAddressBookAnalyticsLogger(),
            routable: noopRoutable
        )
    }
}

// MARK: - Record builders

private extension TransactionDetailsPreviewFactory {
    // Matches `EthereumWalletManagerMock`'s address so the mapper treats it as the current wallet.
    static let walletAddress = "0xtestaddress"
    static let counterpartyAddress = "0x90F79bf6EB2c4f870365E785982E1f101E93b906"
    static let validatorAddress = "0x1234abcd5678ef901234abcd5678ef901234abcd"
    /// USDT on Ethereum — the contract an approve is sent to, and what the sheet shows as the approved token.
    static let tokenContractAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    /// LI.FI diamond — a router an approve typically grants an allowance to. Never the token contract itself.
    static let spenderAddress = "0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE"

    static var ethTokenItem: TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }

    static var btcTokenItem: TokenItem {
        .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
    }

    static func feeAmount(_ value: Decimal) -> Fee {
        Fee(Amount(with: ethTokenItem.blockchain, type: ethTokenItem.amountType, value: value))
    }

    static func onChainRecord(
        hash: String,
        type: TransactionRecord.TransactionType,
        isOutgoing: Bool,
        status: TransactionRecord.TransactionStatus = .confirmed,
        source: TransactionRecord.Source,
        destination: TransactionRecord.Destination,
        fee: Decimal = 0.00056,
        extraInfo: TransactionHistoryExpressExtraInfo? = nil,
        isFromYieldContract: Bool = false
    ) -> TransactionRecord {
        let record = TransactionRecord(
            hash: hash,
            index: 0,
            source: .single(source),
            destination: .single(destination),
            fee: feeAmount(fee),
            status: status,
            isOutgoing: isOutgoing,
            type: type,
            date: Date(),
            tokenTransfers: [],
            isFromYieldContract: isFromYieldContract,
            nonce: 0
        )

        guard let extraInfo else {
            return record
        }

        return record.withExpressExtraInfo(extraInfo)
    }

    // MARK: Swap

    static func swapRecord(hash: String, status: ExpressTransactionStatus) -> TransactionRecord {
        onChainRecord(
            hash: hash,
            type: .transfer,
            isOutgoing: true,
            source: .init(address: walletAddress, amount: 0.5),
            destination: .init(address: .user(payInAddress), amount: 0.5),
            extraInfo: exchangeExtraInfo(status: status)
        )
    }

    static func exchangeExtraInfo(status: ExpressTransactionStatus) -> TransactionHistoryExpressExtraInfo {
        let fromCurrency = ethTokenItem.expressCurrency.asCurrency
        let toCurrency = btcTokenItem.expressCurrency.asCurrency

        let transaction = ExchangeTransaction(
            txId: "swap-preview-tx-id",
            providerId: "changenow",
            status: status,
            rateType: .float,
            externalTx: ExternalTxInfo(id: "swap-external", url: URL(string: "https://changenow.io")),
            fromAddress: walletAddress,
            payIn: PayInInfo(address: payInAddress, extraId: nil, hash: nil),
            payOut: PayOutInfo(address: payOutAddress, hash: nil),
            refund: nil,
            from: ExpressHistoryAsset(currency: fromCurrency, amount: 0.5, actualAmount: nil, decimals: 18),
            to: ExpressHistoryAsset(currency: toCurrency, amount: 0.012, actualAmount: status == .finished ? 0.012 : nil, decimals: 8),
            createdAt: Date(),
            updatedAt: Date(),
            payTill: nil,
            averageDuration: nil
        )

        return .exchange(ExchangeTransactionInfo(
            transaction: transaction,
            provider: nil,
            cryptoCurrencies: [fromCurrency: ethTokenItem, toCurrency: btcTokenItem]
        ))
    }

    // MARK: Onramp

    static func onrampRecord(hash: String, status: OnrampTransactionStatus) -> TransactionRecord {
        onChainRecord(
            hash: hash,
            type: .transfer,
            isOutgoing: false,
            source: .init(address: payOutAddress, amount: 0.065),
            destination: .init(address: .user(walletAddress), amount: 0.065),
            extraInfo: onrampExtraInfo(status: status)
        )
    }

    static func onrampExtraInfo(status: OnrampTransactionStatus) -> TransactionHistoryExpressExtraInfo {
        let toCurrency = ethTokenItem.expressCurrency.asCurrency

        let transaction = OnrampTransaction(
            txId: "onramp-preview-tx-id",
            providerId: "mercuryo",
            status: status,
            failReason: nil,
            externalTx: ExternalTxInfo(id: "onramp-external", url: URL(string: "https://mercuryo.io")),
            payOut: PayOutInfo(address: walletAddress, hash: nil),
            from: OnrampHistoryFiatAsset(currencyCode: "EUR", amount: 250),
            to: OnrampHistoryCryptoAsset(
                currency: toCurrency,
                amount: status == .expired ? nil : 0.065,
                actualAmount: status == .finished ? 0.065 : nil,
                decimals: 18
            ),
            paymentMethod: "card",
            countryCode: "DE",
            createdAt: Date(),
            updatedAt: Date()
        )

        return .onramp(OnrampTransactionInfo(
            transaction: transaction,
            provider: nil,
            fiatCurrency: nil,
            cryptoCurrencies: [toCurrency: ethTokenItem]
        ))
    }

    static let payInAddress = "0xPayInAddress0000000000000000000000000001"
    static let payOutAddress = "0xPayOutAddress000000000000000000000000002"
}

// MARK: - Shared builders

private extension TransactionDetailsPreviewFactory {
    static func icon(_ name: String, color: Color? = nil) -> TokenIconInfo {
        TokenIconInfo(name: name, blockchainIconAsset: nil, imageURL: nil, isCustom: false, customTokenColor: color)
    }
}
