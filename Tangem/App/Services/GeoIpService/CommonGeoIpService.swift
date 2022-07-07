//
//  GeoIpService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class CommonGeoIpService {
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    
    private let provider = MoyaProvider<TangemApiTarget>()
    private var bag: Set<AnyCancellable> = []
}

extension CommonGeoIpService: GeoIpService {
    func regionCode() -> AnyPublisher<String, Never> {
        let card = cardsRepository.lastScanResult.card
        let target = TangemApiTarget(type: .geo, card: card)
        
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(GeoResponse.self)
            .map(\.code)
            .catch { _ -> AnyPublisher<String, Never> in
                Just(Locale.current.regionCode?.lowercased() ?? "")
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
