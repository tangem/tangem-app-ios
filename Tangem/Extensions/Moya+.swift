//
//  Moya+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

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

protocol TimeoutIntervalProvider {
    var timeoutInterval: TimeInterval? { get }
}

class TimeoutIntervalPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let timeoutIntervalProvider = target as? TimeoutIntervalProvider,
           let timeoutInterval = timeoutIntervalProvider.timeoutInterval {
            var mutableRequest = request
            mutableRequest.timeoutInterval = timeoutInterval
            return mutableRequest
        }

        return request
    }
}

extension Response {
    func filterResponseThrowingTangemAPIError(allowRedirectCodes: Bool) throws -> Moya.Response {
        let filteredResponse: Response

        do {
            filteredResponse = try allowRedirectCodes
                ? filterSuccessfulStatusAndRedirectCodes()
                : filterSuccessfulStatusCodes()
        } catch {
            // Trying to map `TangemAPIError` from the response with a status code different than 2XX/3XX
            throw TangemAPIErrorMapper.map(response: self) ?? error
        }

        // Trying to map `TangemAPIError` from the response with a 2XX/3XX status code
        if let tangemAPIError = TangemAPIErrorMapper.map(response: filteredResponse) {
            throw tangemAPIError
        }

        return filteredResponse
    }

    func mapAPIResponseThrowingTangemAPIError<D: Decodable>(allowRedirectCodes: Bool, decoder: JSONDecoder = .init()) throws -> D {
        let filteredResponse = try filterResponseThrowingTangemAPIError(allowRedirectCodes: allowRedirectCodes)

        return try filteredResponse.map(D.self, using: decoder)
    }
}
