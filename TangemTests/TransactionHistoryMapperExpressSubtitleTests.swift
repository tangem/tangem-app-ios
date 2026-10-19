//
//  TransactionHistoryMapperExpressSubtitleTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import BlockchainSdk
@testable import Tangem
@testable import TangemExpress

@Suite("TransactionHistoryMapper Express row (subtitle & amount)")
struct TransactionHistoryMapperExpressSubtitleTests {
    // MARK: - Type

    @Test("Exchange record maps to the swap type; onramp record maps to the onramp type")
    func expressTypes() {
        #expect(makeSUT().mapTransactionViewModel(swapRecord(isOutgoing: true)).transactionType == .swap)
        #expect(makeSUT().mapTransactionViewModel(onrampRecord(status: .finished, toActualAmount: 1)).transactionType == .onramp)
    }

    // MARK: - Subtitle

    @Test("Swap subtitle shows the counterparty currency with the direction of the viewed leg")
    func swapSubtitleCounterparty() {
        // Viewing the ETH (from) leg → counterparty is the received BTC (to) leg, prefixed `to:`.
        let outgoing = makeSUT().mapTransactionViewModel(swapRecord(isOutgoing: true))
        guard case .express(let model)? = outgoing.display.subtitle else {
            Issue.record("expected an express subtitle for a swap")
            return
        }
        #expect(model.direction == .outgoing)
        #expect(model.symbol == ExpressMergeTestDataFactory.bitcoinToken.currencySymbol)
        #expect(model.owner == nil)
        guard case .token = model.leading else {
            Issue.record("expected a token leading icon")
            return
        }

        // Viewing the BTC (to) leg → counterparty is the sent ETH (from) leg, prefixed `from:`.
        let incoming = makeSUT().mapTransactionViewModel(swapRecord(isOutgoing: false))
        guard case .express(let incomingModel)? = incoming.display.subtitle else {
            Issue.record("expected an express subtitle for a swap")
            return
        }
        #expect(incomingModel.direction == .incoming)
        #expect(incomingModel.symbol == ExpressMergeTestDataFactory.ethereumToken.currencySymbol)
    }

    @Test("After a Send&Swap to an outside address the row names nobody, while the recipient stays known for the details")
    func sendAndSwapToAnOutsideAddress() async {
        let resolver = SubtitleOwnerResolver(
            blockchain: .ethereum(testnet: false),
            currentUserWalletId: UserWalletId(value: Data()),
            isAccountsMode: false,
            contacts: []
        )

        let viewModel = await withUserWallets([]) {
            makeSUT().mapTransactionViewModel(swapRecord(isOutgoing: true), subtitleOwnerResolver: resolver)
        }

        guard case .express(let model)? = viewModel.display.subtitle else {
            Issue.record("expected an express subtitle for a swap")
            return
        }
        #expect(model.owner == nil)

        guard case .unresolved(_, let fullAddress, _)? = model.counterparty else {
            Issue.record("expected the pay-out address to resolve to an outside one")
            return
        }
        #expect(fullAddress == "0xOut")
    }

    @Test("A swap between two tokens of one account names no counterparty, so the details keep You send / You receive")
    func swapWithinOneAccount() async throws {
        let account = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })

        let model = try #require(await swapSubtitle(sourceAccount: account, destinationAccount: account))

        #expect(model.owner == nil)
        #expect(model.counterparty == nil, "Both legs live in the same account, so there is nobody to name as From / To")
    }

    @Test("A swap into another account of the wallet keeps that account as the counterparty, so the details name From / To")
    func swapIntoAnotherAccount() async throws {
        let source = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })
        let destination = CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }).update { $0.setName("Savings") }

        let model = try #require(await swapSubtitle(sourceAccount: source, destinationAccount: destination))

        guard case .accountInCurrentWallet(let name, _)? = model.counterparty else {
            Issue.record("expected the receiving account as the counterparty")
            return
        }
        #expect(name == "Savings")
        #expect(model.owner == model.counterparty)
    }

    @Test("Onramp subtitle shows the paid fiat with a `from:` prefix and no owner")
    func onrampSubtitleFiat() {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: .waitingForPayment, toActualAmount: nil))
        guard case .express(let model)? = viewModel.display.subtitle else {
            Issue.record("expected an express subtitle for an onramp")
            return
        }
        #expect(model.direction == .incoming)
        #expect(model.symbol == "EUR")
        #expect(model.owner == nil)
        guard case .fiat = model.leading else {
            Issue.record("expected a fiat leading icon")
            return
        }
    }

    @Test("A plain transfer does not produce an express subtitle")
    func plainTransferHasNoExpressSubtitle() {
        let viewModel = makeSUT().mapTransactionViewModel(plainRecord())
        if case .express = viewModel.display.subtitle {
            Issue.record("a non-express row must not use the express subtitle")
        }
    }

    // MARK: - Amount

    @Test("In-progress onramp with an estimated amount shows the `~` prefix and no sign")
    func onrampEstimatedAmountHasTilde() {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: .waitingForPayment, toActualAmount: nil))
        #expect(viewModel.amount.value?.hasPrefix(AppConstants.tildeSign) == true)
        #expect(viewModel.amount.value?.contains(AppConstants.minusSign) == false)
        #expect(viewModel.amount.value?.contains(AppConstants.plusSign) == false)
    }

    @Test("Finished onramp shows the settled amount with a `+` and without the `~` prefix")
    func onrampFinishedAmountIsSigned() {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: .finished, toActualAmount: 1))
        #expect(viewModel.amount.displayValue?.hasPrefix(AppConstants.plusSign) == true)
        #expect(viewModel.amount.displayValue?.contains(AppConstants.tildeSign) == false)
        #expect(viewModel.amount.displayValue?.contains(AppConstants.minusSign) == false)
    }

    @Test("A finished onramp is signed even when the provider never reported the delivered amount")
    func onrampFinishedWithoutActualAmountIsStillSigned() {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: .finished, toActualAmount: nil))
        #expect(viewModel.amount.displayValue?.hasPrefix(AppConstants.plusSign) == true)
        #expect(viewModel.amount.displayValue?.contains(AppConstants.tildeSign) == false)
    }

    @Test("An unsuccessful onramp shows the promised amount unsigned", arguments: [OnrampTransactionStatus.expired, .failed, .refunded])
    func onrampUnsuccessfulAmountIsUnsigned(status: OnrampTransactionStatus) throws {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: status, toActualAmount: nil))
        let value = try #require(viewModel.amount.displayValue)
        #expect(value.hasPrefix("1"))
        #expect(!value.contains(AppConstants.tildeSign))
        #expect(!value.contains(AppConstants.plusSign))
    }

    @Test("An onramp the provider never quoted shows no amount", arguments: [OnrampTransactionStatus.expired, .failed, .waitingForPayment])
    func onrampWithoutAmountShowsNoAmount(status: OnrampTransactionStatus) {
        let record = onrampRecord(
            status: status,
            toAmount: nil,
            toActualAmount: nil,
            hash: ExpressSyntheticTxHelper(txId: "tx").makeSyntheticTxIdentifier()
        )
        let viewModel = makeSUT().mapTransactionViewModel(record)
        #expect(viewModel.amount.value == nil)
        #expect(viewModel.amount.displayValue == nil)
    }

    @Test("An onramp matched to its on-chain receive shows that amount even without a quote", arguments: [OnrampTransactionStatus.finished, .sending])
    func matchedOnrampWithoutQuoteShowsOnChainAmount(status: OnrampTransactionStatus) throws {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: status, toAmount: nil, toActualAmount: nil, hash: "0xReceive"))
        let value = try #require(viewModel.amount.value)
        #expect(value.contains("1"))
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperExpressSubtitleTests {
    func makeSUT() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: "ETH",
            blockchain: .ethereum(testnet: false),
            addressesProvider: StubExpressSubtitleAddressesProvider(walletAddresses: ["0xSource"]),
            showSign: true,
            isToken: false,
            stakingNetwork: .ethereum
        )
    }

    func withUserWallets<T>(_ models: [UserWalletModel], operation: () -> T) async -> T {
        await InjectedDependenciesIsolation.shared.run {
            let previous = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: models)
            defer { InjectedValues[\.userWalletRepository] = previous }
            return operation()
        }
    }

    func swapSubtitle(
        sourceAccount: CryptoAccountModelMock,
        destinationAccount: CryptoAccountModelMock
    ) async -> TransactionDisplayModel.ExpressSubtitle? {
        let fromAddress = "0xOwnFrom"
        let payOutAddress = "0xOwnOut"
        let userWalletModel = SingleAccountUserWalletModelStub(walletModels: [
            WalletModelTestsMock(tokenItem: ExpressMergeTestDataFactory.ethereumToken, isEmpty: false, account: sourceAccount, addresses: [PlainAddress(value: fromAddress, type: .default)]),
            WalletModelTestsMock(tokenItem: ExpressMergeTestDataFactory.bitcoinToken, isEmpty: false, account: destinationAccount, addresses: [PlainAddress(value: payOutAddress, type: .default)]),
        ])
        let resolver = SubtitleOwnerResolver(
            blockchain: .ethereum(testnet: false),
            currentUserWalletId: userWalletModel.userWalletId,
            isAccountsMode: true,
            contacts: []
        )

        let record = swapRecord(isOutgoing: true, fromAddress: fromAddress, payOutAddress: payOutAddress)
        let viewModel = await withUserWallets([userWalletModel]) {
            makeSUT().mapTransactionViewModel(record, subtitleOwnerResolver: resolver)
        }

        guard case .express(let model)? = viewModel.display.subtitle else {
            return nil
        }
        return model
    }

    func baseRecord(hash: String = "hash", isOutgoing: Bool, extraInfo: TransactionHistoryExpressExtraInfo?) -> TransactionRecord {
        let record = TransactionRecord(
            hash: hash,
            index: 0,
            source: .single(.init(address: "0xSource", amount: 1)),
            destination: .single(.init(address: .user("0xDestination"), amount: 1)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            nonce: nil
        )
        return extraInfo.map { record.withExpressExtraInfo($0) } ?? record
    }

    func plainRecord() -> TransactionRecord {
        baseRecord(isOutgoing: true, extraInfo: nil)
    }

    func swapRecord(isOutgoing: Bool) -> TransactionRecord {
        swapRecord(isOutgoing: isOutgoing, fromAddress: "0xFrom", payOutAddress: "0xOut")
    }

    func swapRecord(isOutgoing: Bool, fromAddress: String, payOutAddress: String) -> TransactionRecord {
        let fromCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken)
        let toCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.bitcoinToken)

        let info = ExchangeTransactionInfo(
            transaction: ExpressMergeTestDataFactory.exchangeTransaction(
                txId: "tx",
                status: .sending,
                fromAddress: fromAddress,
                payInAddress: "0xIn",
                payInHash: nil,
                payOutAddress: payOutAddress,
                payOutHash: nil,
                fromCurrency: fromCurrency,
                fromAmount: 1,
                fromActualAmount: nil,
                toCurrency: toCurrency,
                toAmount: 1,
                toActualAmount: nil,
                refund: nil,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            cryptoCurrencies: [
                fromCurrency: ExpressMergeTestDataFactory.ethereumToken,
                toCurrency: ExpressMergeTestDataFactory.bitcoinToken,
            ]
        )
        return baseRecord(isOutgoing: isOutgoing, extraInfo: .exchange(info))
    }

    func onrampRecord(status: OnrampTransactionStatus, toActualAmount: Decimal?) -> TransactionRecord {
        onrampRecord(status: status, toAmount: 1, toActualAmount: toActualAmount)
    }

    func onrampRecord(status: OnrampTransactionStatus, toAmount: Decimal?, toActualAmount: Decimal?, hash: String = "hash") -> TransactionRecord {
        let info = OnrampTransactionInfo(
            transaction: ExpressMergeTestDataFactory.onrampTransaction(
                txId: "tx",
                status: status,
                payOutAddress: "0xOut",
                payOutHash: nil,
                toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken),
                toAmount: toAmount,
                toActualAmount: toActualAmount,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            fiatCurrency: nil,
            cryptoCurrencies: [:]
        )
        return baseRecord(hash: hash, isOutgoing: false, extraInfo: .onramp(info))
    }
}

// MARK: - Stubs

private struct StubExpressSubtitleAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}

private final class SingleAccountUserWalletModelStub: UserWalletModelMock {
    private let id = UserWalletId(value: Data([0x16, 0x49, 0x4]))
    private let manager: AccountModelsManager

    init(walletModels: [any WalletModel]) {
        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = walletModels
        manager = AccountModelsManagerStub(
            account: CryptoAccountModelMock(
                isMainAccount: true,
                walletModelsManager: walletModelsManager,
                onArchive: { _ in }
            )
        )
    }

    override var userWalletId: UserWalletId { id }
    override var accountModelsManager: AccountModelsManager { manager }
    override var config: UserWalletConfig { UserWalletConfigStub() }
}
