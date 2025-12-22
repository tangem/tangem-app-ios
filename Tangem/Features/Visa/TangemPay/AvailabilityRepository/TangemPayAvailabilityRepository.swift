//
//  TangemPayAvailabilityRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol TangemPayAvailabilityRepository {
    var isTangemPayAvailable: Bool { get }
    var availableUserWalletModels: [any UserWalletModel] { get }
    var isTangemPayAvailablePublisher: AnyPublisher<Bool, Never> { get }
    var isUserWalletModelsAvailble: AnyPublisher<Bool, Never> { get }

    var shouldShowGetTangemPay: AnyPublisher<Bool, Never> { get }
    var shouldShowGetTangemPayBanner: AnyPublisher<Bool, Never> { get }
    func userDidCloseGetTangemPayBanner()
}

private struct TangemPayAvailabilityRepositoryKey: InjectionKey {
    static var currentValue: TangemPayAvailabilityRepository = CommonTangemPayAvailabilityRepository()
}

extension InjectedValues {
    var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository {
        get { Self[TangemPayAvailabilityRepositoryKey.self] }
        set { Self[TangemPayAvailabilityRepositoryKey.self] = newValue }
    }
}
