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
    var availableUserWalletModels: [any UserWalletModel] { get }
    var isTangemPayAvailablePublisher: AnyPublisher<Bool, Never> { get }
    var isUserWalletModelsAvailable: Bool { get }
    var isUserWalletModelsAvailablePublisher: AnyPublisher<Bool, Never> { get }

    var shouldShowGetTangemPay: AnyPublisher<Bool, Never> { get }

    func shouldShowGetTangemPayBanner(for customerWalletId: String) -> AnyPublisher<Bool, Never>
    func userDidCloseGetTangemPayBanner()
    func requestEligibility() async -> Bool
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
