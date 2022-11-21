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

class CommonTangemApiService {
    private let provider = TangemProvider<TangemApiTarget>(plugins: [CachePolicyPlugin()])
    private var bag: Set<AnyCancellable> = []

    private let fallbackRegionCode = Locale.current.regionCode?.lowercased() ?? ""
    private var _geoIpRegionCode: String? = nil
    private var authData: TangemApiTarget.AuthData? = nil

    deinit {
        print("CommonTangemApiService deinit")
    }
}

// MARK: - TangemApiService

extension CommonTangemApiService: TangemApiService {
    var geoIpRegionCode: String {
        return _geoIpRegionCode ?? fallbackRegionCode
    }

    func loadTokens(for key: String) -> AnyPublisher<UserTokenList, TangemAPIError> {
        let target = TangemApiTarget(type: .getUserWalletTokens(key: key), authData: authData)

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(UserTokenList.self)
            .mapTangemAPIError()
            .retry(3)
            .eraseToAnyPublisher()
    }

    func saveTokens(list: UserTokenList, for key: String) -> AnyPublisher<Void, TangemAPIError> {
        let target = TangemApiTarget(type: .saveUserWalletTokens(key: key, list: list), authData: authData)

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .mapTangemAPIError()
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func loadCoins(requestModel: CoinsListRequestModel) -> AnyPublisher<[CoinModel], Error> {
        provider
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
            .requestPublisher(TangemApiTarget(type: .rates(coinIds: coinIds,
                                                           currencyId: AppSettings.shared.selectedCurrencyCode),
                                              authData: authData))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RatesResponse.self)
            .eraseError()
            .map { $0.rates }
            .eraseToAnyPublisher()
    }

    func loadReferralProgramInfo(for userWalletId: String) async throws -> ReferralProgramInfo {
        try await performAsyncRequest(for: .loadReferralProgramInfo(userWalletId: userWalletId))
    }

    func participateInReferralProgram(using token: ReferralProgramInfo.Token,
                                      for address: String,
                                      with userWalletId: String) async throws -> ReferralProgramInfo {
        let userInfo = ReferralParticipationRequestBody(walletId: userWalletId,
                                                        networkId: token.networkId,
                                                        tokenId: token.id,
                                                        address: address)
        return try await performAsyncRequest(for: .participateInReferralProgram(userInfo: userInfo))
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
    }

    func setAuthData(_ authData: TangemApiTarget.AuthData) {
        self.authData = authData
    }

    private func performAsyncRequest<T: Decodable>(for type: TangemApiTarget.TargetType) async throws -> T {
        let target = TangemApiTarget(type: type,
                                     authData: authData)
        let response = try await provider.asyncRequest(for: target)
        let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
        return try decodeResponse(filteredResponse.data)
    }

    private func decodeResponse<T: Decodable>(_ responseData: Data) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: responseData)
    }
}
