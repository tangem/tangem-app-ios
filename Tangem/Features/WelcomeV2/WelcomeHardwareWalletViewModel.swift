//
//  WelcomeHardwareWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import struct TangemUIUtils.AlertBinder

final class WelcomeHardwareWalletViewModel: ObservableObject, Identifiable {
    let id = UUID()

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private(set) var isScanning = false
    @Published var alert: AlertBinder?
    @Published var shopWebViewModel: WebViewContainerViewModel?

    private weak var coordinator: WelcomeV2Routable?

    init(coordinator: WelcomeV2Routable) {
        self.coordinator = coordinator
    }

    func onLearnMoreTap() {
        shopWebViewModel = WebViewContainerViewModel(
            url: TangemShopUrlBuilder().url(utmCampaign: .prospect),
            title: "",
            withCloseButton: true,
            withNavigationBar: false
        )
    }

    func onScanTap() {
        Task { [weak self] in
            await self?.scanCard()
        }
    }

    func onCloseTap() {
        coordinator?.closeHardwareWallet()
    }

    @MainActor
    private func scanCard() async {
        isScanning = true
        defer { isScanning = false }

        let cardScanner = CardScannerFactory().makeDefaultScanner()
        let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
        let result = await userWalletCardScanner.scanCard()

        switch result {
        case .error(let error) where error.isCancellationError:
            break

        case .error(let error):
            alert = error.alertBinder

        case .scanTroubleshooting:
            break

        case .onboarding(let input, _):
            coordinator?.openOnboarding(with: input)

        case .success(let cardInfo):
            do {
                guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
                    walletInfo: .cardWallet(cardInfo),
                    keys: .cardWallet(keys: cardInfo.card.wallets)
                ) else {
                    throw UserWalletRepositoryError.cantUnlockWallet
                }
                try userWalletRepository.add(userWalletModel: userWalletModel)
                coordinator?.openMain(with: userWalletModel)
            } catch {
                alert = error.alertBinder
            }
        }
    }
}
