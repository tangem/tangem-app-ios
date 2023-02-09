//
//  ServicesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ServicesManager {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var bag = Set<AnyCancellable>()

    func initialize() {
        exchangeService.initialize()
        tangemApiService.initialize()
        userWalletRepository.initialize()
    }
}

protocol Initializable {
    func initialize()
}
