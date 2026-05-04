//
//  QuickTopUpBannerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI
import TangemExpress
import TangemLocalization

final class QuickTopUpBannerViewModel: ObservableObject {
    @Injected(\.onrampRepository) private var onrampRepository: OnrampRepository

    @Published private(set) var isVisible: Bool = false
    @Published private(set) var chips: [Chip] = []

    private let walletModel: any WalletModel
    private let onOpenOnramp: (PredefinedOnrampParameters) -> Void
    private var bag = Set<AnyCancellable>()

    init(
        walletModel: any WalletModel,
        onOpenOnramp: @escaping (PredefinedOnrampParameters) -> Void
    ) {
        self.walletModel = walletModel
        self.onOpenOnramp = onOpenOnramp

        bind()
    }

    func onChipSelected(_ chipId: Chip.ID) {
        let parameters: PredefinedOnrampParameters

        if chipId == "other" {
            parameters = .none
        } else if let amount = Decimal(string: chipId) {
            parameters = PredefinedOnrampParameters(amount: amount)
        } else {
            parameters = .none
        }

        onOpenOnramp(parameters)
    }

    private func bind() {
        let currencyInfoPublisher = onrampRepository.preferencePublisher
            .map { preference -> CurrencyInfo? in
                guard let country = preference.country, country.onrampAvailable else {
                    return nil
                }

                let code = (preference.currency ?? country.currency).identity.code.uppercased()
                switch code {
                case "USD": return CurrencyInfo(sign: "$")
                case "EUR": return CurrencyInfo(sign: "€")
                default: return nil
                }
            }

        let isZeroBalancePublisher = walletModel.availableBalanceProvider.balanceTypePublisher
            .map { balanceType in
                switch balanceType {
                case .loaded(let amount): return amount == .zero
                case .empty: return true
                default: return false
                }
            }

        Publishers.CombineLatest(currencyInfoPublisher, isZeroBalancePublisher)
            .receiveOnMain()
            .sink { [weak self] currencyInfo, isZeroBalance in
                guard let self else { return }

                if let currencyInfo, isZeroBalance {
                    chips = Self.makeChips(sign: currencyInfo.sign)
                    isVisible = true
                } else {
                    isVisible = false
                }
            }
            .store(in: &bag)
    }

    private static func makeChips(sign: String) -> [Chip] {
        [
            Chip(id: "50", title: "\(sign)50"),
            Chip(id: "200", title: "\(sign)200"),
            Chip(id: "700", title: "\(sign)700"),
            Chip(id: "other", title: Localization.quickTopUpChipOther),
        ]
    }
}

// MARK: - Types

private extension QuickTopUpBannerViewModel {
    struct CurrencyInfo {
        let sign: String
    }
}
