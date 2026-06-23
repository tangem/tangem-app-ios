//
//  MobileWalletPromoService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import Combine

protocol MobileWalletPromoService {
    var shouldShowMobilePromoWalletSelector: Bool { get }
    func setNeedsPromo()
}

private struct MobileWalletPromoServiceKey: InjectionKey {
    static var currentValue: MobileWalletPromoService = CommonMobileWalletPromoService()
}

extension InjectedValues {
    var mobileWalletPromoService: MobileWalletPromoService {
        get { Self[MobileWalletPromoServiceKey.self] }
        set { Self[MobileWalletPromoServiceKey.self] = newValue }
    }
}

// MARK: - CommonMobileWalletPromoService

class CommonMobileWalletPromoService: MobileWalletPromoService {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var shouldShowMobilePromoWalletSelector: Bool { AppSettings.shared.shouldShowMobilePromoWalletSelector }

    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
    }

    func setNeedsPromo() {
        guard userWalletRepository.models.isEmpty else {
            return
        }

        AppSettings.shared.shouldShowMobilePromoWalletSelector = true
    }

    private func bind() {
        userWalletRepository.eventProvider
            .sink { event in
                switch event {
                // Drop the promo only once the user actually creates/adds a wallet.
                // `.locked`/`.unlocked` also fire on ordinary lock/unlock (app background, relaunch),
                // which previously wiped the promo for a referral user before they created a wallet.
                case .inserted:
                    AppSettings.shared.shouldShowMobilePromoWalletSelector = false
                default:
                    break
                }
            }
            .store(in: &bag)
    }
}
