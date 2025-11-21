//
//  StakeKitStakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

class CommonStakeKitStakingAPIService: StakeKitStakingAPIService {
    private let provider: TangemProvider<StakeKitTarget>
    private let credential: StakingAPICredential
    private let apiType: StakeKitAPIType

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    init(provider: TangemProvider<StakeKitTarget>, credential: StakingAPICredential, apiType: StakeKitAPIType = .prod) {
        self.provider = provider
        self.credential = credential
        self.apiType = apiType
    }

    func enabledYields() async throws -> StakeKitDTO.Yield.Enabled.Response {
        try await _request(target: .enabledYields)
    }

    func getYield(id: String, request: StakeKitDTO.Yield.Info.Request) async throws -> StakeKitDTO.Yield.Info.Response {
        try await _request(target: .getYield(id: id, request))
    }

    func getBalances(request: StakeKitDTO.Balances.Request) async throws -> [StakeKitDTO.Balances.Response] {
        try await _request(target: .getBalances([request]))
    }

    func actions(request: StakeKitDTO.Actions.List.Request) async throws -> StakeKitDTO.Actions.List.Response {
        try await _request(target: .actions(request))
    }

    func estimateGasEnterAction(request: StakeKitDTO.EstimateGas.Enter.Request) async throws -> StakeKitDTO.EstimateGas.Enter.Response {
        try await _request(target: .estimateGasEnterAction(request))
    }

    func estimateGasExitAction(request: StakeKitDTO.EstimateGas.Exit.Request) async throws -> StakeKitDTO.EstimateGas.Exit.Response {
        try await _request(target: .estimateGasExitAction(request))
    }

    func estimateGasPendingAction(request: StakeKitDTO.EstimateGas.Pending.Request) async throws -> StakeKitDTO.EstimateGas.Pending.Response {
        try await _request(target: .estimateGasPendingAction(request))
    }

    func enterAction(request: StakeKitDTO.Actions.Enter.Request) async throws -> StakeKitDTO.Actions.Enter.Response {
        try await _request(target: .enterAction(request))
    }

    func exitAction(request: StakeKitDTO.Actions.Exit.Request) async throws -> StakeKitDTO.Actions.Exit.Response {
        try await _request(target: .exitAction(request))
    }

    func pendingAction(request: StakeKitDTO.Actions.Pending.Request) async throws -> StakeKitDTO.Actions.Pending.Response {
        try await _request(target: .pendingAction(request))
    }

    func transaction(id: String) async throws -> StakeKitDTO.Transaction.Response {
        try await _request(target: .transaction(id: id))
    }

    func constructTransaction(id: String, request: StakeKitDTO.ConstructTransaction.Request) async throws -> StakeKitDTO.Transaction.Response {
        try await _request(target: .constructTransaction(id: id, body: request))
    }

    func submitTransaction(id: String, request: StakeKitDTO.SubmitTransaction.Request) async throws -> StakeKitDTO.SubmitTransaction.Response {
        try await _request(target: .submitTransaction(id: id, body: request))
    }

    func submitHash(id: String, request: StakeKitDTO.SubmitHash.Request) async throws {
        try await _request(target: .submitHash(id: id, body: request))
    }
}

private extension CommonStakeKitStakingAPIService {
    func _request(target: StakeKitTarget.Target) async throws {
        _ = try await response(target: target)
    }

    func _request<T: Decodable>(target: StakeKitTarget.Target) async throws -> T {
        return try await decoder.decode(T.self, from: response(target: target).data)
    }

    func response(target: StakeKitTarget.Target) async throws -> Moya.Response {
        let request = StakeKitTarget(apiKey: credential.apiKey, apiType: apiType, target: target)
        var response = try await provider.requestPublisher(request).async()

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            let stakeKitError = tryMapError(target: request, response: response)

            let error = stakeKitError ?? StakeKitHTTPError.badStatusCode(
                response: String(data: response.data, encoding: .utf8),
                code: response.statusCode
            )

            throw error
        }

        return response
    }

    func tryMapError(target: StakeKitTarget, response: Moya.Response) -> Error? {
        do {
            let error = try JSONDecoder().decode(StakeKitAPIError.self, from: response.data)
            return error
        } catch {
            return nil
        }
    }
}

public enum StakeKitHTTPError: Error, LocalizedError {
    case badStatusCode(response: String?, code: Int)

    public var errorDescription: String? {
        switch self {
        case .badStatusCode(let response, let code): response ?? "HTTP error \(code)"
        }
    }
}
