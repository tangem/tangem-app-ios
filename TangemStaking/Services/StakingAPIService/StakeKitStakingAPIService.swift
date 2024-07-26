//
//  StakeKitStakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

class StakeKitStakingAPIService: StakingAPIService {
    private let provider: MoyaProvider<StakeKitTarget>
    private let credential: StakingAPICredential

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(provider: MoyaProvider<StakeKitTarget>, credential: StakingAPICredential) {
        self.provider = provider
        self.credential = credential
    }

    func enabledYields() async throws -> StakeKitDTO.Yield.Enabled.Response {
        try await _request(target: .enabledYields)
    }

    func getYield(request: StakeKitDTO.Yield.Info.Request) async throws -> StakeKitDTO.Yield.Info.Response {
        try await _request(target: .getYield(request))
    }

    func getBalances(request: StakeKitDTO.Balances.Request) async throws -> [StakeKitDTO.Balances.Response] {
        try await _request(target: .getBalances(request))
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

    func submitHash(id: String, request: StakeKitDTO.SubmitHash.Request) async throws -> StakeKitDTO.SubmitHash.Response {
        try await _request(target: .submitHash(id: id, body: request))
    }
}

private extension StakeKitStakingAPIService {
    func _request<T: Decodable>(target: StakeKitTarget.Target) async throws -> T {
        let request = StakeKitTarget(apiKey: credential.apiKey, target: target)
        var response: Moya.Response

        response = try await provider.requestPublisher(request).async()

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            if let expressError = tryMapError(target: request, response: response) {
                throw expressError
            }

            throw error
        }

        return try decoder.decode(T.self, from: response.data)
    }

    func tryMapError(target: StakeKitTarget, response: Moya.Response) -> Error? {
        do {
            let error = try JSONDecoder().decode(StakeKitDTO.APIError.self, from: response.data)
            return error
        } catch {
            return nil
        }
    }
}
