//
//  Moya+.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.05.2022.
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
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
            return .requestParameters(parameters: json ?? [:], encoding: encoding)
        } catch {
            assertionFailure("Encode failed with error: \(error.localizedDescription)")
            return .requestPlain
        }
    }
}
