//
//  CommonPolymarketCLOBService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketCLOBService {
    private let provider: TangemProvider<PolymarketCLOBTarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let mapper = PolymarketMapper()

    init(provider: TangemProvider<PolymarketCLOBTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - PolymarketCLOBService protocol conformance

extension CommonPolymarketCLOBService: PolymarketCLOBService {
    func createCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        try await credentials(.createCredentials, authHeaders: authHeaders)
    }

    func deriveCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        try await credentials(.deriveCredentials, authHeaders: authHeaders)
    }

    func updateBalanceAllowance(credentials: PolymarketL2Credentials, ownerAddress: String) async throws {
        try await send(.updateBalanceAllowance, credentials: credentials, ownerAddress: ownerAddress)
    }

    func balanceAllowance(
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketBalanceAllowance {
        try await balanceAllowance(.balanceAllowance, credentials: credentials, ownerAddress: ownerAddress)
    }

    func placeOrder(
        _ signedOrder: PolymarketSignedOrder,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderPlacement {
        let body: Data

        do {
            body = try encoder.encode(mapper.mapPlaceOrderRequest(signedOrder, apiKey: credentials.apiKey))
        } catch {
            throw PolymarketOrderPlacementError.notSent(underlying: error)
        }

        let target = PolymarketCLOBTarget.Target.placeOrder(body: body)
        let signedTarget = PolymarketCLOBTarget(baseURL: baseURL, target: target, authHeaders: [:])

        let dto: PolymarketDTO.PlaceOrderResponse

        do {
            let authHeaders = try PolymarketL2Auth.headers(
                credentials: credentials,
                ownerAddress: ownerAddress,
                timestamp: String(Int(Date().timeIntervalSince1970)),
                method: signedTarget.method.rawValue,
                requestPath: signedTarget.signedPath,
                body: String(decoding: body, as: UTF8.self)
            )

            dto = try await request(target, authHeaders: authHeaders.values)
        } catch let error as CancellationError {
            throw error
        } catch let error as PolymarketOrderPlacementError {
            throw error
        } catch let error as PolymarketAPIError {
            throw Self.placementError(from: error)
        } catch {
            throw PolymarketOrderPlacementError.ambiguous(underlying: error)
        }

        guard dto.success else {
            throw PolymarketOrderPlacementError.rejected(message: dto.errorMsg)
        }

        return mapper.mapPlaceOrder(dto)
    }

    func order(
        id: String,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderRecord {
        let signedTarget = PolymarketCLOBTarget(baseURL: baseURL, target: .order(id: id), authHeaders: [:])

        let authHeaders = try PolymarketL2Auth.headers(
            credentials: credentials,
            ownerAddress: ownerAddress,
            timestamp: String(Int(Date().timeIntervalSince1970)),
            method: signedTarget.method.rawValue,
            requestPath: signedTarget.signedPath
        )

        let dto: PolymarketDTO.OrderRecordResponse = try await request(.order(id: id), authHeaders: authHeaders.values)

        return try mapper.mapOrderRecord(dto)
    }
}

// MARK: - Order placement errors

extension CommonPolymarketCLOBService {
    static func placementError(from error: PolymarketAPIError) -> PolymarketOrderPlacementError {
        guard case .http(let statusCode, let problemDetail) = error, (400 ..< 500).contains(statusCode) else {
            return .ambiguous(underlying: error)
        }

        let message = problemDetail?.detail ?? problemDetail?.title

        guard let message, message.localizedCaseInsensitiveContains(Constants.noMatchMarker) else {
            return .rejected(message: message)
        }

        return .noLiquidity(message: message)
    }

    private enum Constants {
        static let noMatchMarker = "no orders found to match"
    }
}

// MARK: - Private implementation

private extension CommonPolymarketCLOBService {
    func credentials(
        _ target: PolymarketCLOBTarget.Target,
        authHeaders: PolymarketCLOBAuthHeaders
    ) async throws -> PolymarketL2Credentials {
        let dto: PolymarketDTO.CredentialsResponse = try await request(target, authHeaders: authHeaders.values)

        return PolymarketL2Credentials(apiKey: dto.apiKey, secret: dto.secret, passphrase: dto.passphrase)
    }

    @discardableResult
    func send(
        _ target: PolymarketCLOBTarget.Target,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> Data {
        let signedTarget = PolymarketCLOBTarget(baseURL: baseURL, target: target, authHeaders: [:])

        let authHeaders = try PolymarketL2Auth.headers(
            credentials: credentials,
            ownerAddress: ownerAddress,
            timestamp: String(Int(Date().timeIntervalSince1970)),
            method: signedTarget.method.rawValue,
            requestPath: signedTarget.signedPath
        )

        return try await data(target, authHeaders: authHeaders.values)
    }

    func balanceAllowance(
        _ target: PolymarketCLOBTarget.Target,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketBalanceAllowance {
        let data = try await send(target, credentials: credentials, ownerAddress: ownerAddress)
        let dto = try decode(PolymarketDTO.BalanceAllowanceResponse.self, from: data)

        guard let balance = Self.collateralAmount(from: dto.balance) else {
            throw PolymarketAPIError.decoding(field: "balance", value: dto.balance)
        }

        let allowance = try dto.allowance.map { rawValue throws -> Decimal in
            guard let allowance = Self.collateralAmount(from: rawValue) else {
                throw PolymarketAPIError.decoding(field: "allowance", value: rawValue)
            }

            return allowance
        }

        return PolymarketBalanceAllowance(balance: balance, allowance: allowance)
    }

    func request<T: Decodable>(
        _ target: PolymarketCLOBTarget.Target,
        authHeaders: [String: String]
    ) async throws -> T {
        try decode(T.self, from: await data(target, authHeaders: authHeaders))
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }

    func data(_ target: PolymarketCLOBTarget.Target, authHeaders: [String: String]) async throws -> Data {
        let request = PolymarketCLOBTarget(baseURL: baseURL, target: target, authHeaders: authHeaders)

        do {
            let response = try await provider.requestPublisher(request).async()
            return try response.filterSuccessfulStatusAndRedirectCodes().data
        } catch let error as CancellationError {
            throw error
        } catch let error as MoyaError {
            throw CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }
}

// MARK: - Collateral amounts

extension CommonPolymarketCLOBService {
    static func collateralAmount(from rawValue: String) -> Decimal? {
        guard let amount = Decimal(stringValue: rawValue) else {
            return nil
        }

        return amount / pow(10, PolymarketCollateral.decimalCount)
    }
}
