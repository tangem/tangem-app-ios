//
//  TransactionHistoryTransferCollapserTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

/// The expected behavior follows the swap merge spec:
/// https://app.notion.com/p/tangem/Swap-3db5d34eb67880729c01c8952a5a3c6f
@Suite("TransactionHistoryTransferCollapser")
struct TransactionHistoryTransferCollapserTests {
    // MARK: - Folding

    @Test("Two transfers to the same counterparty become one row carrying their total")
    func transfersToTheSameCounterpartyAreSummed() throws {
        let collapsed = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1),
            transfer(index: 1, from: Self.owner, to: Self.pool, amount: try #require(Decimal(stringValue: "0.5"))),
        ])

        let record = try #require(collapsed.singleElement)
        #expect(record.isOutgoing)
        #expect(record.singleSourceAddress == Self.owner)
        #expect(try #require(record.source.sources.singleElement).amount == Decimal(stringValue: "1.5"))
        #expect(record.singleDestinationAddress == Self.pool)
    }

    @Test("The row shows the total the wallet lost, not the gross of the transfers")
    func theRenderedAmountIsTheSignedTotal() throws {
        let collapsed = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 3),
            transfer(index: 1, from: Self.pool, to: Self.owner, amount: 1),
        ])

        let viewModel = makeHistoryMapper().mapTransactionViewModel(try #require(collapsed.singleElement))

        #expect(viewModel.isOutgoing)
        #expect(viewModel.amount.amount == formatted(2, signedBy: AppConstants.minusSign))
    }

    /// Both arguments are the same address: the wallet keeps the EIP-55 casing it generates, while a provider
    /// can report it lower-cased. The row has to read the same either way, and it only does while the wallet's
    /// own side of the folded record stays alone — `TransactionHistoryMapper` matches addresses
    /// case-sensitively the moment there is more than one.
    @Test(
        "A wallet that ends up richer gets an incoming row for the net, whatever case it stores its address in",
        arguments: [
            "0x27Fc19697b269066521EE722Ae5d7FE0c9D5c778",
            "0x27fc19697b269066521ee722ae5d7fe0c9d5c778",
        ]
    )
    func aPositiveTotalRendersAsIncoming(walletAddress: String) throws {
        let asTheProviderSpellsIt = walletAddress.lowercased()

        let collapser = TransactionHistoryTransferCollapser(
            walletModelAddresses: [asTheProviderSpellsIt],
            isEvm: true
        )

        let collapsed = collapser.collapse([
            transfer(index: 0, from: asTheProviderSpellsIt, to: Self.pool, amount: 1),
            transfer(index: 1, from: Self.pool, to: asTheProviderSpellsIt, amount: 3),
        ])

        let viewModel = makeHistoryMapper(walletAddresses: [walletAddress])
            .mapTransactionViewModel(try #require(collapsed.singleElement))

        #expect(!viewModel.isOutgoing)
        #expect(viewModel.amount.amount == formatted(2, signedBy: AppConstants.plusSign))
    }

    @Test("A transaction that nets to zero keeps its row and renders unsigned")
    func aZeroTotalKeepsTheRow() throws {
        let collapsed = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 2),
            transfer(index: 1, from: Self.pool, to: Self.owner, amount: 2),
        ])

        let viewModel = makeHistoryMapper().mapTransactionViewModel(try #require(collapsed.singleElement))

        #expect(!viewModel.amount.amount.hasPrefix(AppConstants.minusSign))
        #expect(!viewModel.amount.amount.hasPrefix(AppConstants.plusSign))
        #expect(viewModel.amount.amount == formatted(0, signedBy: ""))
    }

    /// Several transfers rarely share a meaning worth borrowing from the method that carried them, so what the
    /// balance did names the row instead — and a transaction that moved nothing has nothing to name it after.
    @Test("The folded row is named after the balance change, and falls back to an operation when there is none")
    func theFoldedRowIsNamedAfterItsTotal() throws {
        let moved = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 2, type: .contractMethodIdentifier(id: "0xe21fd0e9")),
            transfer(index: 1, from: Self.owner, to: Self.otherPool, amount: 1, type: .contractMethodIdentifier(id: "0xe21fd0e9")),
        ])

        let movedNothing = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 2, type: .contractMethodIdentifier(id: "0xe21fd0e9")),
            transfer(index: 1, from: Self.pool, to: Self.owner, amount: 2, type: .contractMethodIdentifier(id: "0xe21fd0e9")),
        ])

        #expect(try #require(moved.singleElement).type == .transfer)
        #expect(try #require(movedNothing.singleElement).type == .unknownOperation)
    }

    /// The relayer sent such a transaction and paid its gas, and the details tell that gas from the wallet's own
    /// fee only by the executor call.
    @Test("A folded call through the gasless executor still says the relayer sent it")
    func aFoldedGaslessCallKeepsItsExecutor() throws {
        let executorCall = TransactionRecord.TransactionType.contractMethodIdentifier(id: "0x4b072692")
        let collapsed = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 2, type: executorCall),
            transfer(index: 1, from: Self.pool, to: Self.owner, amount: 1, type: executorCall),
        ])

        #expect(try #require(collapsed.singleElement).type == executorCall)
    }

    @Test("The fee belongs to the transaction, so folding must not add it up per transfer")
    func theFeeIsNotSummed() throws {
        let feeValue = try #require(Decimal(stringValue: "0.01"))
        let fee = Fee(Amount(type: .coin, currencySymbol: Self.currencySymbol, value: feeValue, decimals: 18))
        let collapsed = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1, fee: fee),
            transfer(index: 1, from: Self.owner, to: Self.pool, amount: 1, fee: fee),
        ])

        #expect(try #require(collapsed.singleElement).fee.amount.value == feeValue)
    }

    // MARK: - Counterparty

    @Test("Several counterparties leave nothing to name, so the row stops naming one")
    func severalCounterpartiesHideTheAddress() throws {
        let collapsed = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1),
            transfer(index: 1, from: Self.owner, to: Self.otherPool, amount: 1),
        ])

        let viewModel = makeHistoryMapper().mapTransactionViewModel(try #require(collapsed.singleElement))

        guard case .multiple(let addresses) = viewModel.interactionAddress else {
            Issue.record("Expected several counterparties, got \(viewModel.interactionAddress)")
            return
        }

        #expect(addresses.toSet() == [Self.pool, Self.otherPool])
    }

    @Test("An EVM counterparty spelled two ways is still one counterparty")
    func oneCounterpartySpelledTwoWaysStaysNamed() throws {
        let checksummed = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
        let collapsed = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: checksummed, amount: 1),
            transfer(index: 1, from: Self.owner, to: checksummed.lowercased(), amount: 1),
        ])

        let viewModel = makeHistoryMapper().mapTransactionViewModel(try #require(collapsed.singleElement))

        #expect(viewModel.interactionAddress == .user(checksummed))
    }

    @Test("A contract's zero-amount transfer must not cost an ordinary payment its counterparty")
    func aZeroAmountTransferIsNotCounted() throws {
        let collapsed = makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1),
            transfer(index: 1, from: Self.contract, to: Self.otherPool, amount: 0),
        ])

        let viewModel = makeHistoryMapper().mapTransactionViewModel(try #require(collapsed.singleElement))

        #expect(viewModel.interactionAddress == .user(Self.pool))
    }

    /// Folding names a contract call after the balance it moved, which would otherwise offer the pool it swapped
    /// through among the recipients the send screen suggests.
    @Test("A folded row is not offered as a recent recipient, a plain transfer still is")
    func aFoldedRowIsNotSuggested() throws {
        let swapMethod = TransactionRecord.TransactionType.contractMethodIdentifier(id: "0xe21fd0e9")
        let mapper = makeHistoryMapper()
        let folded = try #require(makeCollapser().collapse([
            transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1, type: swapMethod),
            transfer(index: 1, from: Self.owner, to: Self.pool, amount: 2, type: swapMethod),
        ]).singleElement)

        #expect(mapper.mapSuggestedRecord(folded) == nil)
        #expect(mapper.mapSuggestedRecord(transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1)) != nil)
    }

    // MARK: - What must not be folded

    @Test("A transaction that never touches the wallet is left exactly as it came")
    func anUnrelatedTransactionIsLeftAlone() {
        let records = [
            transfer(index: 0, from: Self.contract, to: Self.pool, amount: 1),
            transfer(index: 1, from: Self.pool, to: Self.otherPool, amount: 2),
        ]

        #expect(makeCollapser().collapse(records) == records)
    }

    @Test("Separate transactions are never folded together")
    func separateTransactionsStaySeparate() {
        let records = [
            transfer(hash: "0xFirst", index: 0, from: Self.owner, to: Self.pool, amount: 1),
            transfer(hash: "0xSecond", index: 0, from: Self.owner, to: Self.pool, amount: 1),
        ]

        #expect(makeCollapser().collapse(records).count == 2)
    }

    @Test("Records of one transaction claimed by different deals keep the classification the Express merge gave them")
    func recordsOfDifferentDealsStaySeparate() throws {
        let enriched = transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1)
            .withExpressExtraInfo(.exchange(makeExchangeInfo(txId: "deal")))
        let plain = transfer(index: 1, from: Self.owner, to: Self.pool, amount: 1)

        let collapsed = makeCollapser().collapse([enriched, plain])

        #expect(collapsed.count == 2)
        #expect(collapsed.filter(\.isEnriched).count == 1)
    }

    @Test("A lone transfer is passed through untouched")
    func aLoneTransferIsUntouched() {
        let records = [transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1)]

        #expect(makeCollapser().collapse(records) == records)
    }

    // MARK: - Wiring

    @Test("The history that reaches the screen is folded, not just the collapser called in isolation")
    func theMergeRoutineFoldsTheHistory() throws {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let merger = ExpressMergeTestDataFactory.makeMerger(
            currentToken: token,
            ownerAddress: Self.owner,
            feeTokenItem: token
        )

        let output = merger.merge(
            bsdkTransactions: [
                transfer(index: 0, from: Self.owner, to: Self.pool, amount: 1),
                transfer(index: 1, from: Self.owner, to: Self.pool, amount: 1),
            ],
            exchangeTransactions: [],
            onrampTransactions: []
        )

        let record = try #require(output.singleElement)
        #expect(try #require(record.source.sources.singleElement).amount == 2)
    }
}

// MARK: - Fixtures

private extension TransactionHistoryTransferCollapserTests {
    static let owner = "0xowner"
    static let pool = "0xpool"
    static let otherPool = "0xotherpool"
    static let contract = "0xcontract"
    static let hash = "0xHash"
    static let currencySymbol = "ETH"

    func makeCollapser() -> TransactionHistoryTransferCollapser {
        TransactionHistoryTransferCollapser(
            walletModelAddresses: [Self.owner],
            isEvm: true
        )
    }

    func makeHistoryMapper(walletAddresses: [String] = [TransactionHistoryTransferCollapserTests.owner]) -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: Self.currencySymbol,
            blockchain: .ethereum(testnet: false),
            addressesProvider: StubCollapserAddressesProvider(walletAddresses: walletAddresses),
            showSign: true,
            isToken: false,
            stakingNetwork: nil
        )
    }

    func formatted(_ amount: Decimal, signedBy sign: String) -> String {
        sign + BalanceFormatter().formatCryptoBalance(amount, currencyCode: Self.currencySymbol)
    }

    /// Mirrors what the history mappers emit per transfer: the moved amount sits on both ends of it.
    func transfer(
        hash: String = TransactionHistoryTransferCollapserTests.hash,
        index: Int,
        from: String,
        to: String,
        amount: Decimal,
        fee: Fee = ExpressMergeTestDataFactory.ethereumToken.zeroFee,
        type: TransactionRecord.TransactionType = .transfer
    ) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: index,
            source: .single(.init(address: from, amount: amount)),
            destination: .single(.init(address: .user(to), amount: amount)),
            fee: fee,
            status: .confirmed,
            isOutgoing: from == Self.owner,
            type: type,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            nonce: nil
        )
    }

    func makeExchangeInfo(txId: String) -> ExchangeTransactionInfo {
        ExchangeTransactionInfo(
            transaction: ExpressMergeTestDataFactory.exchangeTransaction(
                txId: txId,
                status: .finished,
                fromAddress: Self.owner,
                payInAddress: Self.pool,
                payInHash: Self.hash,
                payOutAddress: Self.otherPool,
                payOutHash: nil,
                fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken),
                fromAmount: 1,
                fromActualAmount: nil,
                toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
                toAmount: 1,
                toActualAmount: nil,
                refund: nil,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            cryptoCurrencies: [:]
        )
    }
}

// MARK: - Stubs

private struct StubCollapserAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
