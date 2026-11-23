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
    @Injected(\.onrampRepository) private var injectedOnrampRepository: OnrampRepository
    @Injected(\.onrampUserCurrencyStore) private var onrampUserCurrencyStore: OnrampUserCurrencyStore

    private lazy var onrampRepository: OnrampRepository = FeatureProvider.isAvailable(.onrampCountryByIP)
        ? TangemExpressFactory().makeCountryByIPOnrampRepository(userCurrencyStore: onrampUserCurrencyStore)
        : injectedOnrampRepository

    @Published private(set) var chips: [Chip] = []

    var isVisible: Bool { !chips.isEmpty }

    private let sourceToken: any SendSourceToken
    private let onrampCountryProvider: (() async throws -> OnrampCountry)?
    private let onOpenOnramp: (PredefinedOnrampParameters) -> Void
    private var presetByChipID: [Chip.ID: PredefinedOnrampParameters] = [:]
    private var bag = Set<AnyCancellable>()

    private lazy var isCountryAvailablePublisher: AnyPublisher<Bool, Never> = Future { [onrampCountryProvider] promise in
        Task {
            let country = try? await onrampCountryProvider?()
            promise(.success(country?.onrampAvailable ?? false))
        }
    }
    .eraseToAnyPublisher()

    init(
        sourceToken: any SendSourceToken,
        onrampCountryProvider: (() async throws -> OnrampCountry)?,
        onOpenOnramp: @escaping (PredefinedOnrampParameters) -> Void
    ) {
        self.sourceToken = sourceToken
        self.onrampCountryProvider = onrampCountryProvider
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
                if let country = preference.country, !country.onrampAvailable {
                    return nil
                }

                let currencyCode = preference.currency?.identity.code ?? AppSettings.shared.selectedCurrencyCode

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
            .map { currencyCode, isZeroBalance in isZeroBalance ? currencyCode : nil }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .map { viewModel, currencyCode -> AnyPublisher<String?, Never> in
                guard let currencyCode, viewModel.onrampCountryProvider != nil else {
                    return Just(currencyCode).eraseToAnyPublisher()
                }

                return viewModel.isCountryAvailablePublisher
                    .map { $0 ? currencyCode : nil }
                    .prepend(nil)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receiveOnMain()
            .sink { [weak self] currencyCode in
                guard let self else { return }

                if let currencyCode, let result = makeChips(currencyCode: currencyCode) {
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
            presets[id] = PredefinedOnrampParameters(amount: amount, fiatCurrencyCode: currencyCode)
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
