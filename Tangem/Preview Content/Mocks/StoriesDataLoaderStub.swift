//
//  StoriesDataLoaderStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct StoriesDataLoaderStub: StoriesDataLoader {
    func downloadFile(from url: URL) async throws -> URL {
        throw Error.noStubbedFile
    }

    enum Error: Swift.Error {
        case noStubbedFile
    }
}
