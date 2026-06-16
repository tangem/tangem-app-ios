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

    @Published private(set) var chips: [Chip] = []

    var isVisible: Bool { !chips.isEmpty }

    private let sourceToken: any SendSourceToken
    private let onOpenOnramp: (PredefinedOnrampParameters) -> Void
    private var presetByChipID: [Chip.ID: PredefinedOnrampParameters] = [:]
    private var bag = Set<AnyCancellable>()

    init(
        sourceToken: any SendSourceToken,
        onOpenOnramp: @escaping (PredefinedOnrampParameters) -> Void
    ) {
        self.sourceToken = sourceToken
        self.onOpenOnramp = onOpenOnramp

        bind()
    }

    func onChipSelected(_ chipId: Chip.ID) {
        guard let parameters = presetByChipID[chipId] else { return }
        onOpenOnramp(parameters)
    }

    private func bind() {
        let currencyCodePublisher = onrampRepository.preferencePublisher
            .map { preference -> String? in
                let currencyCode: String

                if let country = preference.country {
                    guard country.onrampAvailable else { return nil }
                    currencyCode = preference.currency?.identity.code ?? AppSettings.shared.selectedCurrencyCode
                } else {
                    currencyCode = AppSettings.shared.selectedCurrencyCode
                }

                switch currencyCode.uppercased() {
                case AppConstants.usdCurrencyCode, AppConstants.eurCurrencyCode:
                    return currencyCode.uppercased()
                default:
                    return nil
                }
            }

        let isZeroBalancePublisher = sourceToken.availableBalanceProvider.balanceTypePublisher
            .map { balanceType in
                switch balanceType {
                case .loaded(let amount): return amount == .zero
                case .empty: return true
                default: return false
                }
            }

        Publishers.CombineLatest(currencyCodePublisher, isZeroBalancePublisher)
            .receiveOnMain()
            .sink { [weak self] currencyCode, isZeroBalance in
                guard let self else { return }

                if let currencyCode, isZeroBalance, let result = makeChips(currencyCode: currencyCode) {
                    chips = result.chips
                    presetByChipID = result.presets
                } else {
                    chips = []
                    presetByChipID = [:]
                }
            }
            .store(in: &bag)
    }

    private func makeChips(currencyCode: String) -> (chips: [Chip], presets: [Chip.ID: PredefinedOnrampParameters])? {
        guard let amounts = Self.presetAmounts(for: currencyCode) else { return nil }

        let formatter = BalanceFormatter()
        let options = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: 0,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: 0)
        )

        var chips: [Chip] = []
        var presets: [Chip.ID: PredefinedOnrampParameters] = [:]

        for amount in amounts {
            let title = formatter.formatFiatBalance(amount, currencyCode: currencyCode, formattingOptions: options)
            let id = UUID().uuidString
            chips.append(Chip(id: id, title: title))
            presets[id] = PredefinedOnrampParameters(amount: amount)
        }

        let otherID = UUID().uuidString
        chips.append(Chip(id: otherID, title: Localization.quickTopUpChipOther))
        presets[otherID] = PredefinedOnrampParameters.none

        return (chips, presets)
    }

    private static func presetAmounts(for currencyCode: String) -> [Decimal]? {
        switch currencyCode {
        case AppConstants.eurCurrencyCode: [50, 200, 650]
        case AppConstants.usdCurrencyCode: [50, 200, 700]
        default: nil
        }
    }
}
