//
//  TokenListSectionInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
struct TokenListSectionInfo {
    let sectionType: SectionType
    let infoProviders: [TokenItemInfoProvider]
}

extension TokenListSectionInfo {
    enum SectionType {
        case titled(title: String)
        case untitled

        var title: String? {
            switch self {
            case .titled(let title):
                return title
            case .untitled:
                return nil
            }
        }
    }
}
