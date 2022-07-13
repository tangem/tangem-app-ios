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

    var regionCode: String {
        if let code = internalRegionCode {
            return code
        }
        return fallbackRegionCode
    }

    private let fallbackRegionCode = Locale.current.regionCode?.lowercased() ?? ""
    private var internalRegionCode: String?
    private let provider = MoyaProvider<TangemApiTarget>()
    private var bag: Set<AnyCancellable> = []
}

extension CommonGeoIpService: GeoIpService {
    func initialize() {
        let card = cardsRepository.lastScanResult.card
        let target = TangemApiTarget(type: .geo, card: card)

        provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(GeoResponse.self)
            .map(\.code)
            .replaceError(with: fallbackRegionCode)
            .sink { [weak self] code in
                self?.internalRegionCode = code
            }.store(in: &bag)
    }
}
