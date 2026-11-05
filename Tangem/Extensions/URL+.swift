//
//  URL+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

extension URL {
    var absoluteStringWithoutQuery: String? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return nil
        }

        components.query = nil
        return components.url?.absoluteString
    }
}
