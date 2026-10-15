//
//  EthereumTransactionJournal.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

struct EthereumTransactionJournal {
    private let wireMockClient: WireMockClient

    init(wireMockClient: WireMockClient) {
        self.wireMockClient = wireMockClient
    }

    func sentRawTransactions() -> [String] {
        wireMockClient
            .findRequestBodiesSync(method: Constants.httpMethod, urlPathPattern: Constants.rpcPathPattern)
            .compactMap(Self.rawTransaction(fromBody:))
    }

    func collectNewRawTransactions(after previous: [String], expectedCount: Int, timeout: TimeInterval = .networkRequest) -> [String] {
        var newTransactions: [String] = []
        let reachedExpected = NSPredicate { _, _ in
            newTransactions = Array(sentRawTransactions().dropFirst(previous.count))
            return newTransactions.count >= expectedCount
        }
        _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: reachedExpected, object: nil)], timeout: timeout)

        let exceededExpected = NSPredicate { _, _ in
            newTransactions = Array(sentRawTransactions().dropFirst(previous.count))
            return newTransactions.count > expectedCount
        }
        _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: exceededExpected, object: nil)], timeout: .quick)
        return newTransactions
    }

    static func approveAmounts(in transactions: [String], spender: String) -> [String] {
        let pattern = Constants.approveSelector + Constants.addressPadding + spender.lowercased().dropHexPrefix() + Constants.uint256Group
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        return transactions.flatMap { transaction in
            let range = NSRange(transaction.startIndex..., in: transaction)
            return regex.matches(in: transaction, range: range).compactMap { match in
                Range(match.range(at: 1), in: transaction).map { transaction[$0].lowercased() }
            }
        }
    }

    static func isApprove(_ transaction: String) -> Bool {
        decodedFields(of: transaction)?.data.prefix(Constants.selectorLength).hexString == Constants.approveSelector
    }

    static func destination(of transaction: String) -> String? {
        decodedFields(of: transaction).map { Constants.hexPrefix + $0.to.hexString }
    }

    private static func decodedFields(of transaction: String) -> (to: [UInt8], data: [UInt8])? {
        guard var bytes = [UInt8](hex: transaction.dropHexPrefix()), let type = bytes.first else {
            return nil
        }

        let layout: (to: Int, data: Int)
        switch type {
        case Constants.TransactionType.eip1559:
            layout = (to: 5, data: 7)
            bytes.removeFirst()
        case Constants.TransactionType.eip2930:
            layout = (to: 4, data: 6)
            bytes.removeFirst()
        default:
            layout = (to: 3, data: 5)
        }

        guard
            let list = RLPDecoder.item(in: bytes[...]),
            list.isList,
            let fields = RLPDecoder.listItems(in: list.payload),
            fields.count > layout.data
        else {
            return nil
        }

        return (to: Array(fields[layout.to]), data: Array(fields[layout.data]))
    }

    private static func rawTransaction(fromBody body: String) -> String? {
        guard
            let data = body.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            json[Constants.methodKey] as? String == Constants.sendRawTransactionMethod,
            let params = json[Constants.paramsKey] as? [Any]
        else {
            return nil
        }

        return params.first as? String
    }
}

private enum RLPDecoder {
    struct Item {
        let payload: ArraySlice<UInt8>
        let isList: Bool
        let totalLength: Int
    }

    static func item(in bytes: ArraySlice<UInt8>) -> Item? {
        guard let prefix = bytes.first else {
            return nil
        }

        let start = bytes.startIndex
        let header: (offset: Int, length: Int, isList: Bool)

        switch prefix {
        case 0x00 ... 0x7F:
            return Item(payload: bytes[start ..< start + 1], isList: false, totalLength: 1)
        case 0x80 ... 0xB7:
            header = (offset: 1, length: Int(prefix) - 0x80, isList: false)
        case 0xB8 ... 0xBF:
            guard let length = length(in: bytes, lengthOfLength: Int(prefix) - 0xB7) else { return nil }
            header = (offset: 1 + Int(prefix) - 0xB7, length: length, isList: false)
        case 0xC0 ... 0xF7:
            header = (offset: 1, length: Int(prefix) - 0xC0, isList: true)
        default:
            guard let length = length(in: bytes, lengthOfLength: Int(prefix) - 0xF7) else { return nil }
            header = (offset: 1 + Int(prefix) - 0xF7, length: length, isList: true)
        }

        let payloadStart = start + header.offset
        let payloadEnd = payloadStart + header.length
        guard payloadEnd <= bytes.endIndex else {
            return nil
        }

        return Item(payload: bytes[payloadStart ..< payloadEnd], isList: header.isList, totalLength: header.offset + header.length)
    }

    static func listItems(in payload: ArraySlice<UInt8>) -> [ArraySlice<UInt8>]? {
        var items: [ArraySlice<UInt8>] = []
        var rest = payload

        while !rest.isEmpty {
            guard let item = item(in: rest) else {
                return nil
            }

            items.append(item.payload)
            rest = rest.dropFirst(item.totalLength)
        }

        return items
    }

    private static func length(in bytes: ArraySlice<UInt8>, lengthOfLength: Int) -> Int? {
        let lengthBytes = bytes.dropFirst().prefix(lengthOfLength)
        guard lengthBytes.count == lengthOfLength else {
            return nil
        }

        return lengthBytes.reduce(0) { $0 << 8 | Int($1) }
    }
}

private extension String {
    func dropHexPrefix() -> String {
        hasPrefix("0x") ? String(dropFirst(2)) : self
    }
}

private extension Array where Element == UInt8 {
    init?(hex: String) {
        guard hex.count.isMultiple(of: 2) else {
            return nil
        }

        var bytes: [UInt8] = []
        bytes.reserveCapacity(hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index ..< next], radix: 16) else {
                return nil
            }

            bytes.append(byte)
            index = next
        }

        self = bytes
    }
}

private extension Sequence where Element == UInt8 {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

private extension EthereumTransactionJournal {
    enum Constants {
        static let httpMethod = "POST"
        static let rpcPathPattern = "/ethereum/?"
        static let methodKey = "method"
        static let paramsKey = "params"
        static let sendRawTransactionMethod = "eth_sendRawTransaction"
        static let approveSelector = "095ea7b3"
        static let selectorLength = 4
        static let hexPrefix = "0x"

        enum TransactionType {
            static let eip2930: UInt8 = 0x01
            static let eip1559: UInt8 = 0x02
        }

        static let addressPadding = "0{24}"
        static let uint256Group = "([0-9a-f]{64})"
    }
}
