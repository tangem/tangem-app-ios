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
                    // reset promo flag when user adds wallet or removes last wallet
                case .unlocked, .locked:
                    AppSettings.shared.shouldShowMobilePromoWalletSelector = false
                default:
                    break
                }
            }
            .store(in: &bag)
    }
}
