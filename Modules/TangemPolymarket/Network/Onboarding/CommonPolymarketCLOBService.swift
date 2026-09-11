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

    func updateBalanceAllowance(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketBalanceAllowance {
        try await balanceAllowance(.updateBalanceAllowance, authHeaders: authHeaders)
    }

    func balanceAllowance(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketBalanceAllowance {
        try await balanceAllowance(.balanceAllowance, authHeaders: authHeaders)
    }
}

// MARK: - Private implementation

private extension CommonPolymarketCLOBService {
    func credentials(
        _ target: PolymarketCLOBTarget.Target,
        authHeaders: PolymarketCLOBAuthHeaders
    ) async throws -> PolymarketL2Credentials {
        let dto: PolymarketDTO.CredentialsResponse = try await request(target, authHeaders: authHeaders)

        return PolymarketL2Credentials(apiKey: dto.apiKey, secret: dto.secret, passphrase: dto.passphrase)
    }

    func balanceAllowance(
        _ target: PolymarketCLOBTarget.Target,
        authHeaders: PolymarketCLOBAuthHeaders
    ) async throws -> PolymarketBalanceAllowance {
        let dto: PolymarketDTO.BalanceAllowanceResponse = try await request(target, authHeaders: authHeaders)

        guard let balance = Self.collateralAmount(from: dto.balance) else {
            throw PolymarketAPIError.decoding(field: "balance", value: dto.balance)
        }

        // An absent allowance stays absent: substituting zero would report the one value that means "not approved"
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
        authHeaders: PolymarketCLOBAuthHeaders
    ) async throws -> T {
        let request = PolymarketCLOBTarget(baseURL: baseURL, target: target, authHeaders: authHeaders)

        do {
            let response = try await provider.requestPublisher(request).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(T.self, from: filtered.data)
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
