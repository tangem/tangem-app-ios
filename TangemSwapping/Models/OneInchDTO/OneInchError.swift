//
//  OneInchError.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct OneInchError: Decodable, LocalizedError {
    public let statusCode: Int?
    public let error: String?
    public let description: String?
    public let requestId: String?

    public var errorDescription: String? {
        description ?? error ?? "Unknown error"
    }
}
