//
//  URL+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension URL: Identifiable {
    public var id: String { absoluteString }
}
