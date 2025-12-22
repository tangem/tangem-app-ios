//
//  UserWalletNameIndexationHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class UserWalletNameIndexationHelper {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func suggestedName(userWalletConfig: UserWalletConfig) -> String {
        guard AppSettings.shared.saveUserWallets else {
            return userWalletConfig.defaultName
        }

        return suggestedName(
            userWalletConfig.defaultName,
            names: userWalletRepository.models.map(\.name)
        )
    }

    func suggestedName(_ rawName: String, names: [String]) -> String {
        if NameComponents(from: rawName) != nil {
            return rawName
        }

        let indicesByNameTemplate = names.reduce(into: [String: Set<Int>]()) { dict, name in
            guard let nameComponents = NameComponents(from: name) else {
                dict[name, default: []].insert(1)
                return
            }

            dict[nameComponents.template, default: []].insert(nameComponents.index)
        }

        let nameTemplate = rawName.trimmed()
        let nameIndex = indicesByNameTemplate.nextIndex(for: nameTemplate)

        if nameIndex == 1 {
            return nameTemplate
        } else {
            return "\(nameTemplate) \(nameIndex)"
        }
    }
}

private extension UserWalletNameIndexationHelper {
    struct NameComponents {
        static let nameComponentsRegex = try! NSRegularExpression(pattern: "^(.+)(\\s+\\d+)$")

        let template: String
        let index: Int

        init?(from rawName: String) {
            let name = rawName.trimmingCharacters(in: .whitespaces)
            let range = NSRange(location: 0, length: name.count)

            guard
                let match = Self.nameComponentsRegex.matches(in: name, range: range).first,
                match.numberOfRanges == 3,
                let templateRange = Range(match.range(at: 1), in: name),
                let indexRange = Range(match.range(at: 2), in: name),
                let index = Int(String(name[indexRange]).trimmingCharacters(in: .whitespaces))
            else {
                return nil
            }

            template = String(name[templateRange])
            self.index = index
        }
    }
}

private extension [String: Set<Int>] {
    func nextIndex(for nameTemplate: String) -> Int {
        let indices = self[nameTemplate, default: []]

        if indices.isEmpty {
            return 1
        }

        for i in 1 ... indices.count {
            if !indices.contains(i) {
                return i
            }
        }

        let defaultIndex = indices.count + 1
        return defaultIndex
    }
}
