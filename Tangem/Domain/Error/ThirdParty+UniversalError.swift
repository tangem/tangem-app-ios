//
//  ThirdParty+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemSdk
import Moya

// MARK: - TangemSdkError

extension TangemSdkError: @retroactive UniversalError {
    public var errorCode: Int {
        if case .underlying(let underlyingError) = self,
           let tangemError = underlyingError as? UniversalError {
            return tangemError.errorCode
        }

        let baseErrorCode = 101000000
        return baseErrorCode + code
    }
}

// MARK: - MoyaError

extension MoyaError: @retroactive UniversalError {
    public var errorCode: Int {
        switch self {
        case .encodableMapping: 108000000
        case .imageMapping: 108000001
        case .jsonMapping: 108000002
        case .objectMapping: 108000003
        case .parameterEncoding: 108000004
        case .requestMapping: 108000005
        case .statusCode: 108000006 // Do not change this code
        case .stringMapping: 108000007
        case .underlying: 108000008
        }
    }

    public var errorDescription: String? {
        if let response, let responseString = String(data: response.data, encoding: .utf8) {
            return "MoyaError: \(responseString)"
        }

        if let underlyingError {
            return "MoyaError: \(underlyingError.localizedDescription)"
        }

        switch self {
        case .imageMapping(let response):
            return "Failed to map data to an Image. \(responseDescription(response) ?? "")"

        case .jsonMapping(let response):
            return "Failed to map data to JSON. \(responseDescription(response) ?? "")"

        case .stringMapping(let response):
            return "Failed to map data to a String. \(responseDescription(response) ?? "")"

        case .statusCode(let response):
            return "Status code didn't fall within the given range. \(responseDescription(response) ?? "")"

        case .underlying(let error, let response):
            if let response, let description = responseDescription(response) {
                return description
            }

            return error.localizedDescription

        case .objectMapping(let error, let response):
            if let description = responseDescription(response) {
                return "Failed to map data to a Decodable object. \(description)"
            }

            return "Failed to map data to a Decodable object. \(error.localizedDescription)"

        case .encodableMapping(let error):
            return "Failed to encode Encodable object into data. \(error.localizedDescription)"

        case .requestMapping(let request):
            return "Failed to map Endpoint to a URLRequest. \(request)"

        case .parameterEncoding(let error):
            return "Failed to encode parameters for URLRequest. \(error.localizedDescription)"
        }
    }

    private func responseDescription(_ response: Response) -> String? {
        guard let responseString = String(data: response.data, encoding: .utf8) else {
            return nil
        }

        return responseString
    }
}
