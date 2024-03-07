//
//  QRCodeParserTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import BlockchainSdk
@testable import Tangem

final class QRCodeParserTests: XCTestCase {
    func testBIP0021() throws {
        let blockchain: Blockchain = .bitcoin(testnet: false)
        let parser = QRCodeParser(
            amountType: .coin,
            blockchain: blockchain,
            decimalCount: blockchain.decimalCount
        )

        // MARK: - Destination address

        testPositiveCase(
            code: "bitcoin:bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            amountText: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "some_garbage=bitcoin:bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            amountText: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            amountText: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            amountText: nil,
            memo: nil,
            parser: parser
        )

        // MARK: - Amount

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=asdasd",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            amountText: nil,
            memo: nil,
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1234.56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: Amount(with: blockchain, type: .coin, value: try XCTUnwrap(Decimal(stringValue: "1234.56789"))),
            amountText: "1234.56789",
            memo: nil,
            parser: parser
        )

        // MARK: - Message

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&memo=a%20random%20memo",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            amountText: nil,
            memo: "a random memo",
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&message=some%20message",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            amountText: nil,
            memo: "some message",
            parser: parser
        )

        testPositiveCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&message=hello",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62",
            amount: nil,
            amountText: nil,
            memo: "hello",
            parser: parser
        )

        // MARK: - Negative cases

        testNegativeCase(
            code: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62?someArgument=someValue&amount=1234.56789",
            destination: "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt61",
            amount: Amount(with: blockchain, type: .coin, value: try XCTUnwrap(Decimal(stringValue: "1334.56789"))),
            amountText: "1334.56789",
            memo: "no memo",
            parser: parser
        )
    }

    private func testPositiveCase(
        code: String,
        destination: String,
        amount: Amount?,
        amountText: String?,
        memo: String?,
        parser: QRCodeParser

    ) {
        let result = parser.parse(code)
        XCTAssertEqual(result.destination, destination)
        XCTAssertEqual(result.amount?.string(), amount?.string())
        XCTAssertEqual(result.amountText, amountText)
        XCTAssertEqual(result.memo, memo)
    }

    private func testNegativeCase(
        code: String,
        destination: String,
        amount: Amount?,
        amountText: String?,
        memo: String?,
        parser: QRCodeParser

    ) {
        let result = parser.parse(code)
        XCTAssertNotEqual(result.destination, destination)
        XCTAssertNotEqual(result.amount?.string(), amount?.string())
        XCTAssertNotEqual(result.amountText, amountText)
        XCTAssertNotEqual(result.memo, memo)
    }
}
