//
//  InfoDictionaryUtils.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

private let infoDictionary = Bundle.main.infoDictionary ?? [:]

public enum InfoDictionaryUtils {
    case appName
    case version
    case bundleVersion
    case bundleURLTypes
    case bundleURLSchemes
    case bundleIdentifier
    case environmentName
    case suiteName
    case bsdkSuiteName

    public func value<T>() -> T? {
        switch self {
        case .appName:
            return infoDictionary["CFBundleDisplayName"] as? T
        case .version:
            return infoDictionary["CFBundleShortVersionString"] as? T
        case .bundleVersion:
            return infoDictionary["CFBundleVersion"] as? T
        case .bundleURLTypes:
            return infoDictionary["CFBundleURLTypes"] as? T
        case .bundleIdentifier:
            return infoDictionary["CFBundleIdentifier"] as? T
        case .bundleURLSchemes:
            guard let dictionary: [[String: Any]] = InfoDictionaryUtils.bundleURLTypes.value() else {
                return nil
            }

            return dictionary.map { $0["CFBundleURLSchemes"] } as? T
        case .environmentName:
            return infoDictionary["ENVIRONMENT_NAME"] as? T
        case .suiteName:
            return infoDictionary["SUITE_NAME"] as? T
        case .bsdkSuiteName:
            return infoDictionary["BSDK_SUITE_NAME"] as? T
        }
    }
}
