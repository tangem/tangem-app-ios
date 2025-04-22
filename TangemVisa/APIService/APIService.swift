//
//  APIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct APIService<Target: TargetType> {
    private let provider: TangemProvider<Target>
    private var decoder: JSONDecoder

    init(
        provider: TangemProvider<Target>,
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
            let errorResponse = try decoder.decode(VisaAPIErrorResponse.self, from: response.data)

            log(target: request, response: response, error: errorResponse.error)
            throw errorResponse.error
        }

        do {
            let apiResponse = try decoder.decode(VisaAPIResponse<T>.self, from: response.data)
            return apiResponse.result
        } catch {
            log(target: request, response: response, error: error)
            throw error
        }
    }

    func log(target: Target, response: Response?, error: Error?) {
        VisaLogger.info(
            "Request target: \(target.path), Task: \(target.task), Response: \(response?.data.count ?? -1) Error: \(String(describing: error))"
        )
    }
}
