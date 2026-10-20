//
//  CollectiblesOpeningMediaProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesOpeningMediaProvider: Sendable {
    func load(from url: URL) async throws -> URL
}
