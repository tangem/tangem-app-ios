//
//  TransactionDetailsProviderIdTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
import TangemLocalization
@testable import Tangem
@testable import TangemExpress

@Suite("TransactionDetailsMenuFactory provider deal ID")
struct TransactionDetailsProviderIdTests {
    private static let expressTxId = "2589dc23-5dee-4d54-a53a-22f6f96435db"
    private static let providerId = "gmb2nytjuxffycnawn"
    private static let knownProvider = ExpressProvider(
        id: "changehero",
        name: "ChangeHero",
        type: .cex,
        exchangeOnlyWithinSingleAddress: false,
        imageURL: nil,
        termsOfUse: nil,
        privacyPolicy: nil,
        recommended: nil,
        slippage: nil,
        isCustomSlippageSupported: false
    )

    @Test("A swap the provider gave an id offers to copy it as Swap ID instead of the Transaction ID")
    func swapWithProviderIdOffersCopyingIt() throws {
        let actions = transactionActions(for: makeRecord(.exchange(makeExchangeInfo(externalTxId: Self.providerId, provider: Self.knownProvider))))

        let swapIdAction = try #require(actions.first { $0.title == Localization.expressSwapId })
        #expect(copiedValue(of: swapIdAction) == Self.providerId)
        #expect(copyToast(of: swapIdAction) == Localization.expressSwapIdCopied)
        #expect(copyKind(of: swapIdAction) == .transactionID)
        #expect(!actions.contains { $0.title == Localization.commonTransactionId })
    }

    @Test("An onramp the provider gave an id offers to copy it as Onramp ID instead of the Transaction ID")
    func onrampWithProviderIdOffersCopyingIt() throws {
        let actions = transactionActions(for: makeRecord(.onramp(makeOnrampInfo(externalTxId: Self.providerId, provider: Self.knownProvider))))

        let onrampIdAction = try #require(actions.first { $0.title == Localization.expressOnrampId })
        #expect(copiedValue(of: onrampIdAction) == Self.providerId)
        #expect(copyToast(of: onrampIdAction) == Localization.expressOnrampIdCopied)
        #expect(copyKind(of: onrampIdAction) == .transactionID)
        #expect(!actions.contains { $0.title == Localization.commonTransactionId })
    }

    @Test("A deal the provider hasn't given an id yet keeps the Transaction ID")
    func dealWithoutProviderIdKeepsTransactionId() throws {
        let records = [
            makeRecord(.exchange(makeExchangeInfo(externalTxId: nil, provider: Self.knownProvider))),
            makeRecord(.onramp(makeOnrampInfo(externalTxId: nil, provider: Self.knownProvider))),
        ]

        for record in records {
            let actions = transactionActions(for: record)

            #expect(copiedValue(of: try #require(actions.first { $0.title == Localization.commonTransactionId })) == Self.expressTxId)
            #expect(!actions.contains { [Localization.expressSwapId, Localization.expressOnrampId].contains($0.title) })
        }
    }

    @Test("A shared deal names the provider's id and the on-chain hash, never the Express id")
    func sharedDealNamesTheProviderIdAndHash() throws {
        let records = [
            makeRecord(.exchange(makeExchangeInfo(externalTxId: Self.providerId, provider: Self.knownProvider))),
            makeRecord(.onramp(makeOnrampInfo(externalTxId: Self.providerId, provider: Self.knownProvider))),
        ]

        for record in records {
            let lines = try shareLines(for: record)

            #expect(lines.first == Localization.commonTangem)
            #expect(lines.contains(Localization.expressTransactionId(Self.providerId)))
            #expect(lines.contains(Localization.expressTransactionHash(record.hash)))
            #expect(!lines.contains { $0.contains(Self.expressTxId) })
        }
    }

    @Test("A shared deal the provider hasn't given an id yet has no ID line")
    func sharedDealWithoutProviderIdHasNoIdLine() throws {
        let records = [
            makeRecord(.exchange(makeExchangeInfo(externalTxId: nil, provider: Self.knownProvider))),
            makeRecord(.onramp(makeOnrampInfo(externalTxId: nil, provider: Self.knownProvider))),
        ]

        for record in records {
            let lines = try shareLines(for: record)

            #expect(!lines.contains { $0.hasPrefix(Localization.expressTransactionId("")) })
            #expect(!lines.contains { $0.contains(Self.expressTxId) })
        }
    }

    @Test("A shared deal names its provider only when the provider is known locally")
    func sharedDealNamesOnlyAKnownProvider() throws {
        let known = try shareLines(for: makeRecord(.exchange(makeExchangeInfo(externalTxId: nil, provider: Self.knownProvider))))
        #expect(known.contains(Localization.expressByProviderPlaceholder("ChangeHero CEX")))

        let records = [
            makeRecord(.exchange(makeExchangeInfo(externalTxId: nil, provider: nil))),
            makeRecord(.onramp(makeOnrampInfo(externalTxId: nil, provider: nil))),
        ]

        for record in records {
            #expect(!(try shareLines(for: record)).contains { $0.hasPrefix(Localization.expressByProviderPlaceholder("")) })
        }
    }

    @Test("A shared onramp says what fiat was sent and what crypto was received")
    func sharedOnrampSendsFiatAndReceivesCrypto() throws {
        let lines = try shareLines(for: makeRecord(.onramp(makeOnrampInfo(externalTxId: Self.providerId, provider: Self.knownProvider))))

        #expect(lines.contains { $0.hasPrefix("\(Localization.commonSend) ") && $0.hasSuffix(" EUR") })
        #expect(lines.contains { $0.hasPrefix("\(Localization.commonReceive) ") && $0.hasSuffix(" ETH") })
        #expect(!lines.contains { $0.hasPrefix(Localization.commonBuy) })
    }
}

// MARK: - Helpers

private extension TransactionDetailsProviderIdTests {
    func shareLines(for record: TransactionRecord) throws -> [String] {
        try #require(TransactionDetailsMenuFactory.shareText(for: record, context: makeContext())).components(separatedBy: "\n")
    }

    func transactionActions(for record: TransactionRecord) -> [TransactionDetailsHeaderViewData.MenuAction] {
        let sections = TransactionDetailsMenuFactory.menuSections(
            for: record,
            counterpartyAddress: nil,
            transactionType: .swap,
            context: makeContext(),
            addContactHelper: TransactionDetailsAddContactHelper(
                networkId: AddressBookNetworkID(Blockchain.ethereum(testnet: false).networkId),
                contacts: [],
                isAddressBookSynced: true,
                transactionType: .swap,
                interactionAddress: .custom(message: ""),
                subtitleOwner: nil
            )
        )

        return sections.first { $0.id == "transaction" }?.actions ?? []
    }

    func copiedValue(of action: TransactionDetailsHeaderViewData.MenuAction) -> String? {
        guard case .copy(let value, _, _) = action.action else {
            return nil
        }

        return value
    }

    func copyToast(of action: TransactionDetailsHeaderViewData.MenuAction) -> String? {
        guard case .copy(_, let toast, _) = action.action else {
            return nil
        }

        return toast
    }

    func copyKind(of action: TransactionDetailsHeaderViewData.MenuAction) -> TransactionDetailsViewModel.ViewAction.CopyKind? {
        guard case .copy(_, _, let kind) = action.action else {
            return nil
        }

        return kind
    }

    func makeContext() -> TransactionDetailsContext {
        TransactionDetailsContext(
            walletModel: CommonWalletModel.previewWalletModel(history: []),
            userWalletInfo: UserWalletInfo(
                name: "Test",
                id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
                config: UserWalletConfigStub(),
                backupState: .valid,
                refcode: nil,
                signerFactory: TangemSignerFactory(),
                emailDataProvider: EmailDataProviderStub()
            ),
            isAccountsMode: false
        )
    }

    func makeRecord(_ extraInfo: TransactionHistoryExpressExtraInfo) -> TransactionRecord {
        TransactionRecord(
            hash: "0xPayIn",
            index: 0,
            source: .single(.init(address: "0xFrom", amount: 1)),
            destination: .single(.init(address: .user("0xIn"), amount: 1)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            nonce: nil
        )
        .withExpressExtraInfo(extraInfo)
    }

    func makeExchangeInfo(externalTxId: String?, provider: ExpressProvider?) -> ExchangeTransactionInfo {
        let fromCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken)
        let toCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.bitcoinToken)

        return ExchangeTransactionInfo(
            transaction: ExchangeTransaction(
                txId: Self.expressTxId,
                providerId: "changehero",
                status: .finished,
                rateType: nil,
                externalTx: externalTxId.map {
                    ExternalTxInfo(id: $0, url: URL(string: "https://changehero.io/exchange-transaction/processing?id=\($0)"))
                },
                fromAddress: "0xFrom",
                payIn: PayInInfo(address: "0xIn", extraId: nil, hash: "0xPayIn"),
                payOut: PayOutInfo(address: "bc1qOut", hash: "PayOutHash"),
                refund: nil,
                from: ExpressHistoryAsset(currency: fromCurrency, amount: 1, actualAmount: 1, decimals: 18),
                to: ExpressHistoryAsset(currency: toCurrency, amount: 0.05, actualAmount: 0.05, decimals: 8),
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate,
                payTill: nil,
                averageDuration: nil
            ),
            provider: provider,
            cryptoCurrencies: [
                fromCurrency: ExpressMergeTestDataFactory.ethereumToken,
                toCurrency: ExpressMergeTestDataFactory.bitcoinToken,
            ]
        )
    }

    func makeOnrampInfo(externalTxId: String?, provider: ExpressProvider?) -> OnrampTransactionInfo {
        OnrampTransactionInfo(
            transaction: OnrampTransaction(
                txId: Self.expressTxId,
                providerId: "mercuryo",
                status: .finished,
                failReason: nil,
                externalTx: externalTxId.map { ExternalTxInfo(id: $0, url: nil) },
                payOut: PayOutInfo(address: "0xOut", hash: "0xPayOut"),
                from: OnrampHistoryFiatAsset(currencyCode: "EUR", amount: 100),
                to: OnrampHistoryCryptoAsset(
                    currency: ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken),
                    amount: 1,
                    actualAmount: 1,
                    decimals: 18
                ),
                paymentMethod: "card",
                countryCode: "DE",
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: provider,
            fiatCurrency: nil,
            cryptoCurrencies: [:]
        )
    }
}
