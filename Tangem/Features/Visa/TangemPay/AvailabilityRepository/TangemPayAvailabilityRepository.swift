//
//  TangemPayAvailabilityRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay

enum TangemPayWalletSelectionType: Equatable {
    case single(_ id: String)
    case multiple(_ ids: [String])

    var userWalletModelsIds: [String] {
        switch self {
        case .single(let id): return [id]
        case .multiple(let ids): return ids
        }
    }
}

enum TangemPayOfferAvailability {
    case available(walletSelection: TangemPayWalletSelectionType)
    case notAvailable

    var availableWalletSelection: TangemPayWalletSelectionType? {
        switch self {
        case .available(let selection): return selection
        case .notAvailable: return nil
        }
    }

    var isAvailable: Bool {
        switch self {
        case .available: true
        case .notAvailable: false
        }
    }
}

protocol TangemPayAvailabilityRepository {
    var tangemPayOfferAvailability: TangemPayOfferAvailability { get }
    var tangemPayDetailsEntrypointEligibleWalletSelectionPublisher: AnyPublisher<TangemPayWalletSelectionType?, Never> { get }

    func tangemPayBannerEntrypointEligibleWalletSelectionPublisher(
        for customerWalletId: String
    ) -> AnyPublisher<TangemPayWalletSelectionType?, Never>
    func userDidCloseGetTangemPayBanner()
    func requestEligibleDistributionChannels() async -> [TangemPayDistributionChannel]
    func isEligible(for channel: TangemPayDistributionChannel) -> Bool
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
