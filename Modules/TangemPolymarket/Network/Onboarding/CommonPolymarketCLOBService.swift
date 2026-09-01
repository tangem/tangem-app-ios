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
