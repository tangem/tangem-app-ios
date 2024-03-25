//
//  InfoDictionaryUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum InfoDictionaryUtils {
    case appName
    case version
    case bundleVersion
    case bundleIdentifier
    case bundleURLTypes
    case bundleURLSchemes

    func value<T>() -> T? {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        switch self {
        case .appName:
            return infoDictionary["CFBundleDisplayName"] as? T
        case .version:
            return infoDictionary["CFBundleShortVersionString"] as? T
        case .bundleVersion:
            return infoDictionary["CFBundleVersion"] as? T
        case .bundleIdentifier:
            return infoDictionary["CFBundleIdentifier"] as? T
        case .bundleURLTypes:
            return infoDictionary["CFBundleURLTypes"] as? T
        case .bundleURLSchemes:
            guard let dictionary: [[String: Any]] = InfoDictionaryUtils.bundleURLTypes.value() else {
                return nil
            }

            return dictionary.map { $0["CFBundleURLSchemes"] } as? T
        }
    }
}
