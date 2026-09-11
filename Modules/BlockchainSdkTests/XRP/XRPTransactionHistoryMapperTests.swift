//
//  XRPTransactionHistoryMapperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

struct XRPTransactionHistoryMapperTests {
    private let blockchain = Blockchain.xrp(curve: .secp256k1)
    private let walletAddress = "rWallet"

    @Test(arguments: [
        "OfferCreate",
        "OfferCancel",
        "AccountDelete",
        "EscrowFinish",
        "EscrowCancel",
    ])
    func mapsAmountlessOperation(transactionType: String) throws {
        let record = try #require(try mapCoinTransaction(transactionType: transactionType))

        #expect(record.type == .contractMethodName(name: transactionType))
        #expect(record.source == .single(.init(address: walletAddress, amount: 0)))
        #expect(record.destination == .single(.init(address: .user(walletAddress), amount: 0)))
    }

    @Test
    func skipsAmountlessPayment() throws {
        let record = try mapCoinTransaction(transactionType: "Payment")

        #expect(record == nil)
    }

    @Test
    func mapsEscrowCreateAmount() throws {
        let record = try #require(
            try mapCoinTransaction(
                transactionType: "EscrowCreate",
                destination: "rDestination",
                amount: .drops("1000000")
            )
        )

        #expect(record.type == .contractMethodName(name: "EscrowCreate"))
        #expect(record.source == .single(.init(address: walletAddress, amount: 1)))
        #expect(record.destination == .single(.init(address: .user("rDestination"), amount: 1)))
    }

    @Test
    func mapsClawbackFromHolderToIssuer() throws {
        let issuer = "rIssuer"
        let token = makeToken(issuer: issuer)
        let transaction = makeTransaction(
            transactionType: "Clawback",
            account: issuer,
            amount: .issuedCurrency(.init(currency: "USD", issuer: walletAddress, value: "10"))
        )

        let record = try #require(try mapTransaction(transaction, amountType: .token(value: token)))

        #expect(record.type == .contractMethodName(name: "Clawback"))
        #expect(record.isOutgoing)
        #expect(record.source == .single(.init(address: walletAddress, amount: 10)))
        #expect(record.destination == .single(.init(address: .user(issuer), amount: 10)))
    }

    @Test
    func mapsTokenPaymentWithMatchingIssuer() throws {
        let issuer = "rIssuer"
        let destination = "rDestination"
        let token = makeToken(issuer: issuer)
        let transaction = makeTransaction(
            transactionType: "Payment",
            account: walletAddress,
            destination: destination,
            amount: .issuedCurrency(.init(currency: "USD", issuer: issuer, value: "10"))
        )

        let record = try #require(try mapTransaction(transaction, amountType: .token(value: token)))

        #expect(record.type == .transfer)
        #expect(record.source == .single(.init(address: walletAddress, amount: 10)))
        #expect(record.destination == .single(.init(address: .user(destination), amount: 10)))
    }

    @Test
    func skipsTokenPaymentWithMismatchedIssuer() throws {
        let token = makeToken(issuer: "rIssuer")
        let transaction = makeTransaction(
            transactionType: "Payment",
            account: walletAddress,
            amount: .issuedCurrency(.init(currency: "USD", issuer: "rOtherIssuer", value: "10"))
        )

        let record = try mapTransaction(transaction, amountType: .token(value: token))

        #expect(record == nil)
    }

    @Test
    func skipsClawbackWithMismatchedIssuer() throws {
        let token = makeToken(issuer: "rIssuer")
        let transaction = makeTransaction(
            transactionType: "Clawback",
            account: "rOtherIssuer",
            amount: .issuedCurrency(.init(currency: "USD", issuer: walletAddress, value: "10"))
        )

        let record = try mapTransaction(transaction, amountType: .token(value: token))

        #expect(record == nil)
    }

    @Test
    func skipsUnsupportedTransactionType() throws {
        let record = try mapCoinTransaction(transactionType: "AccountSet")

        #expect(record == nil)
    }

    private func mapCoinTransaction(
        transactionType: String,
        destination: String? = nil,
        amount: XRPTransactionAmount? = nil
    ) throws -> TransactionRecord? {
        let transaction = makeTransaction(
            transactionType: transactionType,
            account: walletAddress,
            destination: destination,
            amount: amount
        )

        return try mapTransaction(transaction, amountType: .coin)
    }

    private func mapTransaction(
        _ transaction: XRPTransactionInfo,
        amountType: Amount.AmountType
    ) throws -> TransactionRecord? {
        try XRPTransactionHistoryMapper(blockchain: blockchain)
            .mapToTransactionRecords([transaction], walletAddress: walletAddress, amountType: amountType)
            .first
    }

    private func makeToken(issuer: String) -> Token {
        Token(
            name: "USD",
            symbol: "USD",
            contractAddress: "USD.\(issuer)",
            decimalCount: 2
        )
    }

    private func makeTransaction(
        transactionType: String,
        account: String,
        destination: String? = nil,
        amount: XRPTransactionAmount? = nil
    ) -> XRPTransactionInfo {
        XRPTransactionInfo(
            tx: XRPHistoryTransaction(
                account: account,
                destination: destination,
                amount: amount,
                limitAmount: nil,
                fee: "12",
                transactionType: transactionType,
                hash: "hash",
                date: nil,
                ledgerIndex: nil
            ),
            meta: .init(transactionResult: "tesSUCCESS"),
            validated: true
        )
    }
}
