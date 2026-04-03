//
//  Moya+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import struct AnyCodable.AnyEncodable

extension Moya.Task {
    static func requestJSONRPC(
        id: Int,
        method: String,
        params: Encodable?,
        encoder: JSONEncoder? = nil
    ) -> Self {
        let jsonRPCParams = JSONRPC.Request(
            jsonrpc: .v2,
            id: id,
            method: method,
            params: params.map(AnyEncodable.init)
        )

        if let encoder = encoder {
            return .requestCustomJSONEncodable(jsonRPCParams, encoder: encoder)
        }

        return .requestJSONEncodable(jsonRPCParams)
    }
}

extension Moya.URLEncoding {
    static var tangem: Self {
        let queryStringEncoding: URLEncoding = .queryString

        return URLEncoding(
            destination: queryStringEncoding.destination,
            arrayEncoding: queryStringEncoding.arrayEncoding,
            boolEncoding: .literal
        )
    }
}

extension Moya.Response {
    func tryMap<Output, Failure>(
        output: Output.Type,
        failure: Failure.Type,
        using decoder: JSONDecoder = JSONDecoder(),
        failsOnEmptyData: Bool = true
    ) throws -> Output where Output: Decodable, Failure: Decodable, Failure: Error {
        if let apiError = try? map(failure, using: decoder, failsOnEmptyData: failsOnEmptyData) {
            throw apiError
        }

        return try map(output, using: decoder, failsOnEmptyData: failsOnEmptyData)
    }
}
