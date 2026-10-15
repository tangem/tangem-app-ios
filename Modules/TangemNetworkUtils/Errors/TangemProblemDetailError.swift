//
//  TangemProblemDetailError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemProblemDetailError: Error, Equatable, Sendable {
    public let httpStatusCode: Int
    public let message: String?
    public let code: String?

    public init(httpStatusCode: Int, message: String?, code: String?) {
        self.httpStatusCode = httpStatusCode
        self.message = message
        self.code = code
    }
}

extension TangemProblemDetailError: Decodable {
    private enum CodingKeys: String, CodingKey {
        case status
        case detail
        case code
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        httpStatusCode = try container.decode(Int.self, forKey: .status)
        message = try container.decodeIfPresent(String.self, forKey: .detail)
        code = try container.decodeIfPresent(String.self, forKey: .code)
    }
}
