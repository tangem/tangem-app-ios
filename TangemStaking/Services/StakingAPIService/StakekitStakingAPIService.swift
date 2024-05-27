//
//  StakekitStakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

class StakekitStakingAPIService: StakingAPIService {
    private let provider: MoyaProvider<StakekitTarget>
    private let credential: StakingAPICredential

    private let decoder: JSONDecoder = .init()

    init(provider: MoyaProvider<StakekitTarget>, credential: StakingAPICredential) {
        self.provider = provider
        self.credential = credential
    }

    func enabledYields() async throws -> StakekitDTO.Yield.Enabled.Response {
        try await _request(target: .enabledYields)
    }

    func getYield(request: StakekitDTO.Yield.Info.Request) async throws -> StakekitDTO.Yield.Info.Response {
        try await _request(target: .getYield(request))
    }

    func enterAction(request: StakekitDTO.Actions.Enter.Request) async throws -> StakekitDTO.Actions.Enter.Response {
        try await _request(target: .enterAction(request))
    }
}

private extension StakekitStakingAPIService {
    func _request<T: Decodable>(target: StakekitTarget.Target) async throws -> T {
        let request = StakekitTarget(apiKey: credential.apiKey, target: target)
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

    func tryMapError(target: StakekitTarget, response: Moya.Response) -> Error? {
        do {
            let error = try JSONDecoder().decode(StakekitDTO.APIError.self, from: response.data)
            return error
        } catch {
            return nil
        }
    }
}
