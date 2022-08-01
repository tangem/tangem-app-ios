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

    var value: String? {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        switch self {
        case .appName:
            return infoDictionary["CFBundleDisplayName"] as? String
        case .version:
            return infoDictionary["CFBundleShortVersionString"] as? String
        case .bundleVersion:
            return infoDictionary["CFBundleVersion"] as? String
        }
    }
}
