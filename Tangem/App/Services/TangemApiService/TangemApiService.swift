//
//  TangemApiService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TangemApiService: AnyObject, Initializable {
    var geoIpRegionCode: String { get }

    func loadCoins(requestModel: CoinsListRequestModel) -> AnyPublisher<[CoinModel], Error>
    func loadRates(for coinIds: [String]) -> AnyPublisher<[String: Decimal], Never>
    func loadCurrencies() -> AnyPublisher<[CurrenciesResponse.Currency], Error>

    func loadTokens() -> AnyPublisher<[Data], Error>
    func saveTokens(tokens: [Data]) -> AnyPublisher<Void, Error>

    func setAuthData(_ authData: TangemApiTarget.AuthData)
}

private struct TangemApiServiceKey: InjectionKey {
    static var currentValue: TangemApiService = CommonTangemApiService()
}

extension InjectedValues {
    var tangemApiService: TangemApiService {
        get { Self[TangemApiServiceKey.self] }
        set { Self[TangemApiServiceKey.self] = newValue }
    }
}
