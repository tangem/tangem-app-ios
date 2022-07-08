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
        
        let fallbackRegionCode = Locale.current.regionCode?.lowercased() ?? ""
        
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(GeoResponse.self)
            .map(\.code)
            .replaceError(with: fallbackRegionCode)
            .eraseToAnyPublisher()
    }
}
