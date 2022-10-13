//
//  Moya+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya

extension Task {
    /// A request url parameters set with `Encodable` type
    static func requestURLEncodable<Value: Encodable>(
        _ value: Value,
        encoder: JSONEncoder = JSONEncoder(),
        encoding: URLEncoding = .default
    ) -> Task {
        do {
            let data = try encoder.encode(value)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return .requestParameters(parameters: json ?? [:], encoding: encoding)
        } catch {
            assertionFailure("Encode failed with error: \(error.localizedDescription)")
            return .requestPlain
        }
    }
}

protocol CachePolicyProvider {
    var cachePolicy: URLRequest.CachePolicy { get }
}

class CachePolicyPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let cachePolicyGettable = target as? CachePolicyProvider {
            var mutableRequest = request
            mutableRequest.cachePolicy = cachePolicyGettable.cachePolicy
            return mutableRequest
        }

        return request
    }
}
