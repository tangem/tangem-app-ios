//
//  APIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct APIService<Target: TargetType, ErrorType: Error & Decodable> {
    private let provider: MoyaProvider<Target>
    private var decoder: JSONDecoder

    init(
        provider: MoyaProvider<Target>,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.decoder = decoder
    }

    func request<T: Decodable>(_ request: Target) async throws -> T {
        var response: Response
        do {
            response = try await provider.asyncRequest(request)
        } catch {
            log(target: request, response: nil, error: error)
            throw error
        }

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
            log(target: request, response: response, error: nil)
        } catch {
            if let apiError = tryMapError(target: request, response: response) {
                throw apiError
            }

            throw error
        }

        do {
            return try decoder.decode(T.self, from: response.data)
        } catch {
            log(target: request, response: response, error: error)
            throw error
        }
    }

    func tryMapError(target: Target, response: Response) -> ErrorType? {
        do {
            let error = try JSONDecoder().decode(ErrorType.self, from: response.data)
            log(target: target, response: response, error: error)
            return error
        } catch {
            log(target: target, response: response, error: error)
            return nil
        }
    }

    func log(target: Target, response: Response?, error: Error?) {
        VisaLogger.info(
            "Request target: \(target.path), Task: \(target.task), Response: \(response?.data.count ?? -1) Error: \(String(describing: error))"
        )
    }
}
