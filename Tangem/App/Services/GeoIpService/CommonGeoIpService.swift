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
    
    private var regionCode: String = ""
    private let provider = MoyaProvider<TangemApiTarget>()
    private var bag: Set<AnyCancellable> = []
}

extension CommonGeoIpService: GeoIpService {
    func initialize() {
        let card = cardsRepository.lastScanResult.card
        let target = TangemApiTarget(type: .geo, card: card)
        
        let fallbackRegionCode = Locale.current.regionCode?.lowercased() ?? ""
        
        provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(GeoResponse.self)
            .map(\.code)
            .replaceError(with: fallbackRegionCode)
            .sink { [weak self] code in
                self?.regionCode = code
            }.store(in: &bag)

    }
    
    func getRegionCode() -> String {
        if regionCode.isEmpty {
            return Locale.current.regionCode?.lowercased() ?? ""
        } else {
            return regionCode
        }
    }
}
