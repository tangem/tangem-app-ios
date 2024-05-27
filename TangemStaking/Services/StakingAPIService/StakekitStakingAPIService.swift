//
//  StakekitStakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import BlockchainSdk
import TangemFoundation

public protocol StakingAPIProvider {
    func enabledYields() async throws -> [YieldInfo]
    func yieldInfo(integrationId: String) async throws -> YieldInfo
}

class CommonStakingAPIProvider: StakingAPIProvider {
    let service: StakingAPIService
    let mapper: StakekitMapper

    init(service: StakingAPIService, mapper: StakekitMapper) {
        self.service = service
        self.mapper = mapper
    }

    func enabledYields() async throws -> [YieldInfo] {
        let response = try await service.enabledYields()
        let yieldInfos = try response.data.map(mapper.mapToYieldInfo(from:))
        return yieldInfos
    }

    func yieldInfo(integrationId: String) async throws -> YieldInfo {
        let response = try await service.getYield(request: .init(integrationId: integrationId))
        let yieldInfo = try mapper.mapToYieldInfo(from: response)
        return yieldInfo
    }
}

struct StakekitMapper {
    func mapToYieldInfo(from response: StakekitDTO.Yield.Info.Response) throws -> YieldInfo {
        try YieldInfo(
            contractAddress: response.token.address,
            apy: response.apy,
            rewardRate: response.rewardRate,
            rewardType: mapToRewardType(from: response.rewardType),
            unbonding: mapToPeriod(from: response.metadata.warmupPeriod),
            minimumRequirement: response.args.enter.args.amount.minimum,
            rewardClaimingType: mapToRewardClaimingType(from: response.metadata.rewardClaiming),
            warmupPeriod: mapToPeriod(from: response.metadata.withdrawPeriod),
            rewardScheduleType: mapToRewardScheduleType(from: response.metadata.rewardSchedule)
        )
    }

    // MARK: - Inner types

    func mapToRewardType(from rewardType: StakekitDTO.Yield.Info.Response.RewardType) -> RewardType {
        switch rewardType {
        case .apr: .apr
        case .apy: .apy
        case .variable: .variable
        }
    }

    func mapToPeriod(from period: StakekitDTO.Yield.Info.Response.Metadata.Period) -> Period {
        switch period {
        case .days(let days): .days(days)
        }
    }

    func mapToRewardClaimingType(from type: StakekitDTO.Yield.Info.Response.Metadata.RewardClaiming) -> RewardClaimingType {
        switch type {
        case .auto: .auto
        case .manual: .manual
        }
    }

    func mapToRewardScheduleType(from type: StakekitDTO.Yield.Info.Response.Metadata.RewardScheduleType) throws -> RewardScheduleType {
        switch type {
        case .block: .block
        case .hour:
            throw StakekitMapperError.notImplement
        case .day:
            throw StakekitMapperError.notImplement
        case .week:
            throw StakekitMapperError.notImplement
        case .month:
            throw StakekitMapperError.notImplement
        case .era:
            throw StakekitMapperError.notImplement
        case .epoch:
            throw StakekitMapperError.notImplement
        }
    }
}

enum StakekitMapperError: Error {
    case notImplement
    case noData(String)
}

protocol StakingAPIService {
    func enabledYields() async throws -> StakekitDTO.Yield.Enabled.Response
    func getYield(request: StakekitDTO.Yield.Info.Request) async throws -> StakekitDTO.Yield.Info.Response
}

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

struct StakekitTarget: Moya.TargetType {
    let apiKey: String
    let target: Target

    enum Target {
        // Yields
        case enabledYields
        case getYield(StakekitDTO.Yield.Info.Request)
//        case getAction(id: String)
//        case createAction()
    }

    var baseURL: URL {
        URL(string: "https://api.stakek.it")!
    }

    var path: String {
        switch target {
        case .enabledYields:
            return "yields/enabled"
        case .getYield(let stakekitDTO):
            return "yields/\(stakekitDTO.integrationId)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getYield, .enabledYields:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getYield, .enabledYields:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        ["X-API-KEY": apiKey]
    }
}
