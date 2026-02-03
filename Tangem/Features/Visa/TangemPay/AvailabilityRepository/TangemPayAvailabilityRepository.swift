//
//  TangemPayAvailabilityRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

enum TangemPayWalletSelectionType {
    case single(UserWalletModel)
    case multiple([UserWalletModel])

    var wallets: [UserWalletModel] {
        switch self {
        case .single(let wallet): return [wallet]
        case .multiple(let wallets): return wallets
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
    var shouldShowGetTangemPay: AnyPublisher<Bool, Never> { get }

    func shouldShowGetTangemPayBanner(
        for customerWalletId: String
    ) -> AnyPublisher<Bool, Never>
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
