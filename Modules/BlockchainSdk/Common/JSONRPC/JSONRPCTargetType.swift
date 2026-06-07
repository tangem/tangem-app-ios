//
//  JSONRPCTargetType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya
import struct AnyCodable.AnyEncodable

protocol JSONRPCTargetType: TargetType {
    static func nextRequestID() -> Int

    var rpcMethod: String { get }
    var params: [AnyEncodable] { get }
}

extension JSONRPCTargetType {
    var path: String { "" }
    var method: Moya.Method { .post }

    var task: Task {
        let request = JSONRPC.Request(id: Self.nextRequestID(), method: rpcMethod, params: params)
        return .requestJSONEncodable(request)
    }
}
