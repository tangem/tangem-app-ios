//
//  MoralisCursorPaginator.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MoralisCursorPaginator {
    static let pageSize = 100

    static func loadAllPages<Response: MoralisPaginableResponse>(
        loadPage: (_ cursor: String?) async throws -> Response
    ) async -> (value: [Response], errors: [NFTErrorDescriptor]) {
        var results: [Response] = []
        var errors: [NFTErrorDescriptor] = []
        var cursor: String?

        repeat {
            do {
                let response = try await loadPage(cursor)

                results.append(response)
                cursor = response.cursor
            } catch {
                errors.append(
                    NFTErrorDescriptor(
                        code: error.networkErrorCodeOrNSErrorFallback,
                        description: error.localizedDescription
                    )
                )
            }
        } while cursor != nil

        return (results, errors: errors)
    }
}
