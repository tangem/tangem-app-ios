//
//  UserWalletNameIndexationHelper.swift
//  Tangem
//
//  Created by Andrey Chukavin on 17.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletNameIndexationHelper {
    private var indexesByNameTemplate: [String: [Int]] = [:]
    private let nameComponentsRegex = try! NSRegularExpression(pattern: "^(.+)(\\s+\\d+)$")

    init(mode: Mode, names: [String]) {
        for name in names {
            guard let nameComponents = nameComponents(from: name) else {
                if mode == .newName {
                    addIndex(1, for: name)
                }
                continue
            }

            let indexesByNameTemplate = indexesByNameTemplate[nameComponents.template] ?? []
            if !indexesByNameTemplate.contains(nameComponents.index) {
                addIndex(nameComponents.index, for: nameComponents.template)
            }
        }
    }

    func suggestedName(_ rawName: String) -> String {
        if let _ = nameComponents(from: rawName) {
            return rawName
        }

        let nameTemplate = rawName.trimmingCharacters(in: .whitespaces)
        let nameIndex = nextIndex(for: nameTemplate)

        addIndex(nameIndex, for: nameTemplate)

        if nameIndex == 1 {
            return nameTemplate
        } else {
            return "\(nameTemplate) \(nameIndex)"
        }
    }

    private func addIndex(_ index: Int, for nameTemplate: String) {
        let newIndexes = (indexesByNameTemplate[nameTemplate] ?? []) + [index]
        indexesByNameTemplate[nameTemplate] = newIndexes.sorted()
    }

    private func nextIndex(for nameTemplate: String) -> Int {
        let indexes = indexesByNameTemplate[nameTemplate] ?? []

        for i in 1 ... 100 {
            if !indexes.contains(i) {
                return i
            }
        }

        let defaultIndex = indexes.count + 1
        return defaultIndex
    }

    private func nameComponents(from rawName: String) -> NameComponents? {
        let name = rawName.trimmingCharacters(in: .whitespaces)
        let range = NSRange(location: 0, length: name.count)

        guard
            let match = nameComponentsRegex.matches(in: name, range: range).first,
            match.numberOfRanges == 3,
            let templateRange = Range(match.range(at: 1), in: name),
            let indexRange = Range(match.range(at: 2), in: name),
            let index = Int(String(name[indexRange]).trimmingCharacters(in: .whitespaces))
        else {
            return nil
        }

        let template = String(name[templateRange])
        return NameComponents(template: template, index: index)
    }
}

extension UserWalletNameIndexationHelper {
    enum Mode {
        case migration
        case newName
    }
}

private extension UserWalletNameIndexationHelper {
    struct NameComponents {
        let template: String
        let index: Int
    }
}
