//
//  JSONRPC.Request.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum JSONRPC {
    /// https://www.jsonrpc.org/specification#request_object
    struct Request<Parameter>: Encodable where Parameter: Encodable {
        let jsonrpc: Version?
        let id: Int
        let method: String
        let params: Parameter?

        init(jsonrpc: Version? = .v2, id: Int, method: String, params: Parameter?) {
            self.jsonrpc = jsonrpc
            self.id = id
            self.method = method
            self.params = params
        }
    }

    /// https://www.jsonrpc.org/specification#response_object
    struct Response<Output, Failure> where Output: Decodable, Failure: Decodable, Failure: Swift.Error {
        let jsonrpc: String
        let id: Int
        let result: Swift.Result<Output, Failure>
    }

    struct APIError: Codable, LocalizedError {
        let code: Int?
        let message: String?

        var errorDescription: String? {
            let values = [code.map { "code: \($0)" }, message.map { "message: \($0)" }]
            return values.compactMap { $0 }.joined(separator: ", ")
        }
    }

    enum Version: String, Encodable {
        case v2 = "2.0"
    }
}

// MARK: - Request + Encoding

extension JSONRPC.Request {
    func string(encoder: JSONEncoder = .init()) throws -> String {
        let messageData = try encoder.encode(self)

        guard let string = String(bytes: messageData, encoding: .utf8) else {
            throw Errors.invalidRequest
        }

        return string
    }

    enum Errors: LocalizedError {
        case invalidRequest
    }
}

// MARK: - Result + Decoding

extension JSONRPC.Response: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let result: Result<Output, Failure>

        if container.contains(.result) {
            // We can't use `decodeIfPresent` here because in this case
            // When `result` is absent or `{ result: null }` the same
            result = try .success(container.decode(forKey: .result))
        } else if container.contains(.error) {
            result = try .failure(container.decode(forKey: .error))
        } else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Neither \"result\" nor \"error\" keys present in the JSON payload"
            )
            throw DecodingError.valueNotFound(type(of: result), context)
        }

        self.init(
            jsonrpc: try container.decode(forKey: .jsonrpc),
            id: try container.decode(forKey: .id),
            result: result
        )
    }

    enum CodingKeys: CodingKey {
        case jsonrpc
        case id
        case result
        case error
    }
}

// MARK: - Request + Encoding

extension JSONRPC.Request {
    static func ping(
        jsonrpc: JSONRPC.Version? = .v2,
        id: Int = WebSocketConnection.Ping.Constants.id,
        method: String
    ) -> JSONRPC.Request<[String]> {
        // Empty params
        .init(jsonrpc: jsonrpc, id: id, method: method, params: [])
    }
}
