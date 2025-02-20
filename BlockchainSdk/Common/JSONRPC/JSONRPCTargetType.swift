//
//  JSONRPCTargetType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya

protocol JSONRPCTargetType: TargetType {
    static var id: Int { get set }

    var rpcMethod: String { get }
    var params: AnyEncodable { get }
}

extension JSONRPCTargetType {
    var path: String { "" }
    var method: Moya.Method { .post }

    var task: Task {
        assert(params.isArray(), "The JSONRPC `params` must be wrapped to array")
        Self.id += 1
        let request = JSONRPC.Request(id: Self.id, method: rpcMethod, params: params)
        return .requestJSONEncodable(request)
    }
}

extension AnyEncodable {
    static let emptyArray = AnyEncodable([Int]())
}
