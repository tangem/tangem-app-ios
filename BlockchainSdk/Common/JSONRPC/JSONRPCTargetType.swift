//
//  JSONRPCTargetType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya
import TangemFoundation

protocol JSONRPCTargetType: TargetType {
    static var id: ThreadSafeContainer<Int> { get set }

    var rpcMethod: String { get }
    var params: [AnyEncodable] { get }
}

extension JSONRPCTargetType {
    var path: String { "" }
    var method: Moya.Method { .post }

    var task: Task {
        Self.id.mutate { $0 += 1 }
        let request = JSONRPC.Request(id: Self.id.read(), method: rpcMethod, params: params)
        return .requestJSONEncodable(request)
    }
}
