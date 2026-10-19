//
//  TransactionHistoryOnrampAmountPrefixTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem
@testable import TangemExpress

@Suite("Onramp received amount prefix")
struct TransactionHistoryOnrampAmountPrefixTests {
    @Test(
        "History row prefix follows the status, not the actual amount",
        arguments: OnrampTransactionStatus.allCases, [nil, Decimal(2)]
    )
    func historyRowPrefix(status: OnrampTransactionStatus, toActualAmount: Decimal?) throws {
        let viewModel = makeSUT().mapTransactionViewModel(makeRecord(status: status, toActualAmount: toActualAmount))
        let value = try #require(viewModel.amount.value)

        #expect(Self.prefix(of: value) == Self.expectedPrefix(for: status))
    }

    @Test("Details screen prefix follows the status", arguments: OnrampTransactionStatus.allCases)
    func detailsPrefix(status: OnrampTransactionStatus) throws {
        guard case .pair(_, let to) = makeDetails(status: status).tokensData.content else {
            Issue.record("Onramp details must render a pair of legs")
            return
        }

        let amountText = try #require(to.amountText)
        #expect(Self.prefix(of: amountText) == Self.expectedPrefix(for: status))
    }
}

// MARK: - Expected behavior

private extension TransactionHistoryOnrampAmountPrefixTests {
    enum Prefix: Equatable {
        case tilde
        case plus
        case none
    }

    static func expectedPrefix(for status: OnrampTransactionStatus) -> Prefix {
        switch status {
        case .created, .waitingForPayment, .paymentProcessing, .verifying, .paid,
             .sending, .paused, .refunding, .unknown:
            return .tilde
        case .finished:
            return .plus
        case .failed, .expired, .refunded:
            return .none
        }
    }

    static func prefix(of text: String) -> Prefix {
        if text.hasPrefix(AppConstants.tildeSign) {
            return .tilde
        }

        if text.hasPrefix(AppConstants.plusSign) {
            return .plus
        }

        return .none
    }
}

// MARK: - Helpers

private extension TransactionHistoryOnrampAmountPrefixTests {
    func makeSUT() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: "ETH",
            blockchain: .ethereum(testnet: false),
            addressesProvider: StubOnrampAddressesProvider(walletAddresses: ["0xDestination"]),
            showSign: true,
            isToken: false,
            stakingNetwork: .ethereum
        )
    }

    func makeRecord(status: OnrampTransactionStatus, toActualAmount: Decimal?) -> TransactionRecord {
        let record = TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(.init(address: "0xSource", amount: 1)),
            destination: .single(.init(address: .user("0xDestination"), amount: 1)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: false,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            nonce: nil
        )

        let info = OnrampTransactionInfo(
            transaction: ExpressMergeTestDataFactory.onrampTransaction(
                txId: "tx",
                status: status,
                payOutAddress: "0xDestination",
                payOutHash: nil,
                toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
                toAmount: 1,
                toActualAmount: toActualAmount,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            fiatCurrency: nil,
            cryptoCurrencies: [:]
        )

        return record.withExpressExtraInfo(.onramp(info))
    }

    func makeDetails(status: OnrampTransactionStatus) -> TransactionDetailsOnrampViewData {
        TransactionDetailsOnrampViewData(
            stage: TransactionOperationStatusMapper.stage(for: status),
            paid: TransactionDetailsOnrampViewData.PaidLeg(
                amount: "100",
                symbol: "EUR",
                flagIconURL: nil,
                isFlagLoading: false
            ),
            received: TransactionDetailsOnrampViewData.ReceivedLeg(
                destination: .wallet(name: "Wallet"),
                amount: "1",
                symbol: "ETH",
                tokenIconInfo: .remote(name: "Ethereum", imageURL: nil)
            ),
            statusBanner: nil,
            provider: nil,
            rate: nil,
            action: nil
        )
    }
}

// MARK: - Stubs

private struct StubOnrampAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
