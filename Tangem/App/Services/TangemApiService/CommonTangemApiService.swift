//
//  CommonTangemApiService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import BlockchainSdk

class CommonTangemApiService {
    private let provider = TangemProvider<TangemApiTarget>(plugins: [
        CachePolicyPlugin(),
        TimeoutIntervalPlugin(),
        NetworkLoggerPlugin(configuration: .init(
            output: NetworkLoggerPlugin.tangemSdkLoggerOutput,
            logOptions: .verbose
        )),
    ])

    private var bag: Set<AnyCancellable> = []

    private let fallbackRegionCode = Locale.current.regionCode?.lowercased() ?? ""
    private var _geoIpRegionCode: String?
    private var authData: TangemApiTarget.AuthData?

    deinit {
        AppLog.shared.debug("CommonTangemApiService deinit")
    }

    private func request<D: Decodable>(for type: TangemApiTarget.TargetType) async throws -> D {
        let target = TangemApiTarget(type: type, authData: authData)
        return try await provider.asyncRequest(for: target).mapAPIResponse()
    }
}

// MARK: - TangemApiService

extension CommonTangemApiService: TangemApiService {
    var geoIpRegionCode: String {
        return _geoIpRegionCode ?? fallbackRegionCode
    }

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList, TangemAPIError> {
//        let target = TangemApiTarget(type: .getUserWalletTokens(key: key), authData: authData)
//
//        return provider
//            .requestPublisher(target)
//            .filterSuccessfulStatusCodes()
//            .map(UserTokenList.self)
//            .mapTangemAPIError()
//            .retry(3)
//            .eraseToAnyPublisher()
        return Just(UserTokenList(tokens: [])).setFailureType(to: TangemAPIError.self).eraseToAnyPublisher()
    }

    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError> {
//        let target = TangemApiTarget(type: .saveUserWalletTokens(key: key, list: list), authData: authData)
//
//        return provider
//            .requestPublisher(target)
//            .filterSuccessfulStatusCodes()
//            .mapTangemAPIError()
//            .mapVoid()
//            .eraseToAnyPublisher()
        return .anyFail(error: TangemAPIError(code: .decode)).eraseToAnyPublisher()
    }

    func loadCoins(requestModel: CoinsListRequestModel) -> AnyPublisher<[CoinModel], Error> {
        return provider
            .requestPublisher(TangemApiTarget(type: .coins(requestModel), authData: authData))
            .filterSuccessfulStatusCodes()
            .map(CoinsResponse.self)
            .eraseError()
            .map { list -> [CoinModel] in
                list.coins.map { CoinModel(with: $0, baseImageURL: list.imageHost) }
            }
            .map { coinModels in
                guard let contractAddress = requestModel.contractAddress else {
                    return coinModels
                }

                return coinModels.compactMap { coinModel in
                    let items = coinModel.items.filter {
                        let itemContractAddress = $0.contractAddress ?? ""
                        return itemContractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
                    }

                    guard !items.isEmpty else {
                        return nil
                    }

                    return CoinModel(
                        id: coinModel.id,
                        name: coinModel.name,
                        symbol: coinModel.symbol,
                        imageURL: coinModel.imageURL,
                        items: items
                    )
                }
            }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }

    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error> {
        provider
            .requestPublisher(TangemApiTarget(type: .currencies, authData: authData))
            .filterSuccessfulStatusCodes()
            .map(CurrenciesResponse.self)
            .map { $0.currencies.sorted(by: { $0.name < $1.name }) }
            .mapError { _ in AppError.serverUnavailable }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }

    func loadRates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Error> {
        provider
            .requestPublisher(TangemApiTarget(
                type: .rates(
                    coinIds: coinIds,
                    currencyId: AppSettings.shared.selectedCurrencyCode
                ),
                authData: authData
            ))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RatesResponse.self)
            .eraseError()
            .map { $0.rates }
            .eraseToAnyPublisher()
    }

    func loadReferralProgramInfo(for userWalletId: String) async throws -> ReferralProgramInfo {
        let target = TangemApiTarget(
            type: .loadReferralProgramInfo(userWalletId: userWalletId),
            authData: authData
        )
        let response = try await provider.asyncRequest(for: target)
        let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
        return try JSONDecoder().decode(ReferralProgramInfo.self, from: filteredResponse.data)
    }

    func participateInReferralProgram(
        using token: AwardToken,
        for address: String,
        with userWalletId: String
    ) async throws -> ReferralProgramInfo {
        let userInfo = ReferralParticipationRequestBody(
            walletId: userWalletId,
            networkId: token.networkId,
            tokenId: token.id,
            address: address
        )
        let target = TangemApiTarget(
            type: .participateInReferralProgram(userInfo: userInfo),
            authData: authData
        )
        let response = try await provider.asyncRequest(for: target)
        let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
        return try JSONDecoder().decode(ReferralProgramInfo.self, from: filteredResponse.data)
    }

    func promotion(programName: String, timeout: TimeInterval?) async throws -> PromotionParameters {
        try await request(for: .promotion(programName: programName, timeout: timeout))
    }

    @discardableResult
    func validateNewUserPromotionEligibility(walletId: String, code: String) async throws -> PromotionValidationResult {
        try await request(for: .validateNewUserPromotionEligibility(walletId: walletId, code: code))
    }

    @discardableResult
    func validateOldUserPromotionEligibility(walletId: String, programName: String) async throws -> PromotionValidationResult {
        try await request(for: .validateOldUserPromotionEligibility(walletId: walletId, programName: programName))
    }

    @discardableResult
    func awardNewUser(walletId: String, address: String, code: String) async throws -> PromotionAwardResult {
        try await request(for: .awardNewUser(walletId: walletId, address: address, code: code))
    }

    @discardableResult
    func awardOldUser(walletId: String, address: String, programName: String) async throws -> PromotionAwardResult {
        try await request(for: .awardOldUser(walletId: walletId, address: address, programName: programName))
    }

    func initialize() {
        provider
            .requestPublisher(TangemApiTarget(type: .geo, authData: authData))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(GeoResponse.self)
            .map(\.code)
            .replaceError(with: fallbackRegionCode)
            .subscribe(on: DispatchQueue.global())
            .weakAssign(to: \._geoIpRegionCode, on: self)
            .store(in: &bag)

        AppLog.shared.debug("CommonTangemApiService initialized")
    }

    func setAuthData(_ authData: TangemApiTarget.AuthData) {
        self.authData = authData
    }
}

private extension Response {
    func mapAPIResponse<D: Decodable>() throws -> D {
        let filteredResponse = try filterSuccessfulStatusCodes()

        if let baseError = try? filteredResponse.map(TangemBaseAPIError.self) {
            throw baseError.error
        }

        return try filteredResponse.map(D.self)
    }
}
