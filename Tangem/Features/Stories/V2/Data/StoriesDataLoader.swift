//
//  StoriesDataLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Downloads a story asset file to a temporary location; the caller owns moving it to a permanent one.
protocol StoriesDataLoader {
    func downloadFile(from url: URL) async throws -> URL
}
