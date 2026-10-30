//
//  MoralisMediaURLMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum MoralisMediaURLMapper {
    static func map(high: String?, medium: String?, low: String?, original: String?) -> URL? {
        [high, medium, low, original]
            .lazy
            .compactMap(map(_:))
            .first
    }

    static func map(_ urlString: String?) -> URL? {
        urlString?
            .nilIfEmpty
            .flatMap(URL.init(string:))
            .map(NFTIPFSURLConverter.convert(_:))
    }
}
