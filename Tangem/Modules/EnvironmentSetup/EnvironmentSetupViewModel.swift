//
//  EnvironmentSetupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class EnvironmentSetupViewModel: ObservableObject {
    @Injected(\.promotionService) var promotionService: PromotionServiceProtocol

    // MARK: - ViewState

    @Published var appSettingsTogglesViewModels: [DefaultToggleRowViewModel] = []
    @Published var featureStateViewModels: [FeatureStateRowViewModel] = []
    @Published var additionalSettingsViewModels: [DefaultRowViewModel] = []
    @Published var alert: AlertBinder?

    // Promotion
    @Published var currentPromoCode: String = ""
    @Published var finishedPromotionNames: String = ""
    @Published var awardedPromotionNames: String = ""

    // MARK: - Dependencies

    private let featureStorage = FeatureStorage()
    private unowned let coordinator: EnvironmentSetupRoutable
    private var bag: Set<AnyCancellable> = []

    init(coordinator: EnvironmentSetupRoutable) {
        self.coordinator = coordinator

        setupView()
    }

    func setupView() {
        appSettingsTogglesViewModels = [
            DefaultToggleRowViewModel(
                title: "Use testnet",
                isOn: BindingValue<Bool>(
                    root: self,
                    default: false,
                    get: { $0.featureStorage.isTestnet },
                    set: { $0.featureStorage.isTestnet = $1 }
                )
            ),
            DefaultToggleRowViewModel(
                title: "Use dev API",
                isOn: BindingValue<Bool>(
                    root: self,
                    default: false,
                    get: { $0.featureStorage.useDevApi },
                    set: { $0.featureStorage.useDevApi = $1 }
                )
            ),
            DefaultToggleRowViewModel(
                title: "Use fake tx history",
                isOn: BindingValue<Bool>(
                    root: self,
                    default: false,
                    get: { $0.featureStorage.useFakeTxHistory },
                    set: { $0.featureStorage.useFakeTxHistory = $1 }
                )
            ),
        ]

        featureStateViewModels = Feature.allCases.reversed().map { feature in
            FeatureStateRowViewModel(
                feature: feature,
                enabledByDefault: FeatureProvider.isAvailableForReleaseVersion(feature),
                state: BindingValue<FeatureState>(
                    root: self,
                    default: .default,
                    get: { $0.featureStorage.availableFeatures[feature] ?? .default },
                    set: { obj, state in
                        switch state {
                        case .default:
                            obj.featureStorage.availableFeatures.removeValue(forKey: feature)
                        case .on, .off:
                            obj.featureStorage.availableFeatures[feature] = state
                        }
                    }
                )
            )
        }

        additionalSettingsViewModels = [
            DefaultRowViewModel(title: "Supported Blockchains") { [weak self] in
                self?.coordinator.openSupportedBlockchainsPreferences()
            },
        ]

        updateCurrentPromoCode()

        updateFinishedPromotionNames()

        updateAwardedPromotionNames()
    }

    func copyCurrentPromoCode() {
        guard let promoCode = promotionService.promoCode else { return }

        UIPasteboard.general.string = promoCode

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func resetCurrentPromoCode() {
        promotionService.setPromoCode(nil)
        updateCurrentPromoCode()
    }

    func resetFinishedPromotionNames() {
        promotionService.resetFinishedPromotions()
        updateFinishedPromotionNames()
    }

    func resetAward() {
        // [REDACTED_TODO_COMMENT]
//        runTask { [weak self] in
//            guard let self else { return }
//
//            let success = (try? await promotionService.resetAward(cardId: cardId)) != nil
//
//            DispatchQueue.main.async {
//                let feedbackGenerator = UINotificationFeedbackGenerator()
//                feedbackGenerator.notificationOccurred(success ? .success : .error)
//
//                self.updateAwardedPromotionNames()
//            }
//        }
    }

    func showExitAlert() {
        let alert = Alert(
            title: Text("Are you sure you want to exit the app?"),
            primaryButton: .destructive(Text("Exit"), action: { exit(1) }),
            secondaryButton: .cancel()
        )
        self.alert = AlertBinder(alert: alert)
    }

    private func updateCurrentPromoCode() {
        currentPromoCode = promotionService.promoCode ?? "[none]"
    }

    private func updateFinishedPromotionNames() {
        let finishedPromotionNames = promotionService.finishedPromotionNames()
        if finishedPromotionNames.isEmpty {
            self.finishedPromotionNames = "[none]"
        } else {
            self.finishedPromotionNames = promotionService.finishedPromotionNames().joined(separator: ", ")
        }
    }

    private func updateAwardedPromotionNames() {
        let awardedPromotionNames = promotionService.awardedPromotionNames()
        if awardedPromotionNames.isEmpty {
            self.awardedPromotionNames = "[none]"
        } else {
            self.awardedPromotionNames = awardedPromotionNames.joined(separator: ", ")
        }
    }
}
