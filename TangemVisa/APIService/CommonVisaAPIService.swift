//
//  CommonVisaAPIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct CommonVisaAPIService {
    private let provider: MoyaProvider<VisaAPITarget>
    private let logger: InternalLogger
    private var decoder: JSONDecoder

    private let isTestnet: Bool

    init(isTestnet: Bool, provider: MoyaProvider<VisaAPITarget>, logger: InternalLogger) {
        self.provider = provider
        self.logger = logger
        self.isTestnet = isTestnet

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
}

extension CommonVisaAPIService: VisaAPIService {
    func loadHistoryPage(request: VisaTransactionHistoryDTO.APIRequest) async throws -> VisaTransactionHistoryDTO {
        try await _request(target: .transactionHistory(request: request))
    }
}

private extension CommonVisaAPIService {
    func _request<T: Decodable>(target: VisaAPITarget.Target) async throws -> T {
        let request = VisaAPITarget(isTestnet: isTestnet, target: target)
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
            if let expressError = tryMapError(target: request, response: response) {
                throw expressError
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

    func tryMapError(target: VisaAPITarget, response: Response) -> VisaAPIError? {
        do {
            let error = try JSONDecoder().decode(VisaAPIError.self, from: response.data)
            log(target: target, response: response, error: error)
            return error
        } catch {
            log(target: target, response: response, error: error)
            return nil
        }
    }

    func log(target: TargetType, response: Response?, error: Error?) {
        var info = ""
        if let response {
            info = String(data: response.data, encoding: .utf8)!
        }

        logger.debug(
            subsystem: .apiService,
            """
            Request target: \(target.path)
            Task: \(target.task)
            Response: \(info)
            Error: \(String(describing: error))
            """
        )
    }
}
