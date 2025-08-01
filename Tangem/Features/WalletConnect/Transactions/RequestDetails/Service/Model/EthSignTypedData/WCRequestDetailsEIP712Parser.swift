//
//  WCRequestDetailsEIP712Parser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WCRequestDetailsEIP712Parser {
    static func parse(typedData: EIP712TypedData, method: WalletConnectMethod) -> [WCTransactionDetailsSection] {
        var sections: [WCTransactionDetailsSection] = []

        sections.append(contentsOf: createBasicSections(typedData: typedData, method: method))

        if let domainSection = createDomainSection(from: typedData.domain) {
            sections.append(domainSection)
        }

        if let messageSection = createMessageSection(from: typedData.message) {
            sections.append(messageSection)
        }

        return sections
    }

    private static func createBasicSections(typedData: EIP712TypedData, method: WalletConnectMethod) -> [WCTransactionDetailsSection] {
        return [
            .init(sectionTitle: nil, items: [.init(title: "Signature Type", value: method.rawValue)]),
            .init(sectionTitle: nil, items: [.init(title: "Primary Type", value: typedData.primaryType)]),
        ]
    }

    private static func createDomainSection(from json: JSON) -> WCTransactionDetailsSection? {
        guard let domainObject = json.objectValue, domainObject.isNotEmpty else {
            return nil
        }

        let domainItems = createDetailItems(from: domainObject)
        return .init(sectionTitle: "Domain", items: domainItems)
    }

    private static func createMessageSection(from json: JSON) -> WCTransactionDetailsSection? {
        guard let messageObject = json.objectValue, messageObject.isNotEmpty else {
            return nil
        }

        let messageItems = createDetailItems(from: messageObject)
        return .init(sectionTitle: "Message", items: messageItems)
    }

    private static func createDetailItems(from object: [String: JSON]) -> [WCTransactionDetailsSection.WCTransactionDetailsItem] {
        object.map { key, value in
            .init(title: key, value: formatValue(from: value))
        }
    }

    private static func formatValue(from json: JSON) -> String {
        extractSimpleValue(from: json)
    }

    private static func extractSimpleValue(from json: JSON, level: Int = 0, indent: String = "") -> String {
        switch json {
        case .string(let value):
            value
        case .number(let value):
            String(value)
        case .bool(let value):
            String(value)
        case .null:
            "null"
        case .array(let array):
            formatArray(array, level: level, indent: indent)
        case .object(let object):
            formatObject(object, level: level, indent: indent)
        }
    }

    private static func formatArray(_ array: [JSON], level: Int, indent: String) -> String {
        guard array.isNotEmpty else { return "[]" }

        let nextIndent = indent + "  "

        if array.count < 5, array.allSatisfy({ isSimpleValue($0) }) {
            let items = array.map { extractSimpleValue(from: $0, level: level + 1, indent: nextIndent) }

            return "[\(items.joined(separator: ", "))]"
        }

        var result = "[\n"

        for (index, item) in array.enumerated() {
            result += "\(nextIndent)\(extractSimpleValue(from: item, level: level + 1, indent: nextIndent))"

            if index < array.count - 1 {
                result += ","
            }

            result += "\n"
        }

        result += "\(indent)]"

        return result
    }

    private static func formatObject(_ object: [String: JSON], level: Int, indent: String) -> String {
        guard object.isNotEmpty else { return "{}" }

        let nextIndent = indent + "  "

        if object.count < 3, object.allSatisfy({ isSimpleValue($0.value) }) {
            let pairs = object.map { key, value in
                "\(key): \(extractSimpleValue(from: value, level: level + 1, indent: nextIndent))"
            }

            return "{\(pairs.joined(separator: ", "))}"
        }

        var result = "{\n"

        for (index, (key, value)) in object.enumerated() {
            result += "\(nextIndent)\(key): \(extractSimpleValue(from: value, level: level + 1, indent: nextIndent))"

            if index < object.count - 1 {
                result += ","
            }

            result += "\n"
        }

        result += "\(indent)}"

        return result
    }

    private static func isSimpleValue(_ json: JSON) -> Bool {
        switch json {
        case .string, .number, .bool, .null:
            true
        default:
            false
        }
    }
}
