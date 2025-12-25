//
//  EnvironmentSetupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress
import FirebaseMessaging
import TangemVisa
import struct TangemUIUtils.AlertBinder
import TangemStaking

final class EnvironmentSetupViewModel: ObservableObject {
    @Injected(\.promotionService) var promotionService: PromotionServiceProtocol

    // MARK: - ViewState

    @Published var appSettingsTogglesViewModels: [DefaultToggleRowViewModel] = []
    @Published var pickerViewModels: [DefaultPickerRowViewModel] = []
    @Published var featureStateViewModels: [FeatureStateRowViewModel] = []
    @Published var additionalSettingsViewModels: [DefaultRowViewModel] = []
    @Published var alert: AlertBinder?

    /// Demo
    @Published var forcedDemoCardId: String = ""

    /// FirebaseMessaging
    @Published private(set) var fcmToken: String = ""

    // Promotion
    @Published var currentPromoCode: String = ""
    @Published var finishedPromotionNames: String = ""
    @Published var awardedPromotionNames: String = ""

    /// Application UID
    @Published var applicationUid: String = ""

    // MARK: - Dependencies

    private let featureStorage = FeatureStorage.instance
    private weak var coordinator: EnvironmentSetupRoutable?
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
                    root: featureStorage,
                    default: false,
                    get: { $0.isTestnet },
                    set: { $0.isTestnet = $1 }
                )
            ),
            DefaultToggleRowViewModel(
                title: "Enable Performance Monitor",
                isOn: BindingValue<Bool>(
                    root: featureStorage,
                    default: false,
                    get: { $0.isPerformanceMonitorEnabled },
                    set: { $0.isPerformanceMonitorEnabled = $1 }
                )
            ),
            DefaultToggleRowViewModel(
                title: "Mocked CardScanner Enabled",
                isOn: BindingValue<Bool>(
                    root: featureStorage,
                    default: false,
                    get: { $0.isMockedCardScannerEnabled },
                    set: { $0.isMockedCardScannerEnabled = $1 }
                )
            ),
            DefaultToggleRowViewModel(
                title: "Visa API Mocks",
                isOn: BindingValue<Bool>(
                    root: featureStorage,
                    default: false,
                    get: { $0.isVisaAPIMocksEnabled },
                    set: { $0.isVisaAPIMocksEnabled = $1 }
                )
            ),
        ]

        pickerViewModels = [
            DefaultPickerRowViewModel(
                title: "Tangem API type",
                options: TangemAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: TangemAPIType.prod.rawValue,
                    get: { $0.tangemAPIType.rawValue },
                    set: { $0.tangemAPIType = TangemAPIType(rawValue: $1) ?? .prod }
                )
            ),
            DefaultPickerRowViewModel(
                title: "Express API type",
                options: ExpressAPIType.allCases.map { $0.rawValue },
                displayTitles: ExpressAPIType.allCases.map { $0.title },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: ExpressAPIType.production.rawValue,
                    get: { $0.apiExpress },
                    set: { $0.apiExpress = $1 }
                ),
                pickerStyle: .menu
            ),
            DefaultPickerRowViewModel(
                title: "Visa API type",
                options: VisaAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: VisaAPIType.prod.rawValue,
                    get: { $0.visaAPIType.rawValue },
                    set: { $0.visaAPIType = VisaAPIType(rawValue: $1) ?? .prod }
                )
            ),
            DefaultPickerRowViewModel(
                title: "StakeKit staking API type",
                options: StakeKitAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: StakeKitAPIType.prod.rawValue,
                    get: { $0.stakeKitAPIType.rawValue },
                    set: { $0.stakeKitAPIType = StakeKitAPIType(rawValue: $1) ?? .prod }
                )
            ),
            DefaultPickerRowViewModel(
                title: "YieldModule API type",
                options: YieldModuleAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: YieldModuleAPIType.prod.rawValue,
                    get: { $0.yieldModuleAPIType.rawValue },
                    set: { $0.yieldModuleAPIType = YieldModuleAPIType(rawValue: $1) ?? .prod }
                )
            ),
        ]

        featureStateViewModels = Feature.allCases.reversed().map { feature in
            FeatureStateRowViewModel(
                feature: feature,
                enabledByDefault: FeatureProvider.isAvailableForReleaseVersion(feature),
                state: BindingValue<FeatureState>(
                    root: featureStorage,
                    default: .default,
                    get: { $0.availableFeatures[feature] ?? .default },
                    set: { obj, state in
                        switch state {
                        case .default:
                            obj.availableFeatures.removeValue(forKey: feature)
                        case .on, .off:
                            obj.availableFeatures[feature] = state
                        }
                    }
                )
            )
        }

        additionalSettingsViewModels = [
            DefaultRowViewModel(title: "Supported Blockchains", action: { [weak self] in
                self?.coordinator?.openSupportedBlockchainsPreferences()
            }),
            DefaultRowViewModel(title: "Staking Blockchains", action: { [weak self] in
                self?.coordinator?.openStakingBlockchainsPreferences()
            }),
            DefaultRowViewModel(title: "NFT-enabled Blockchains", action: { [weak self] in
                self?.coordinator?.openNFTBlockchainsPreferences()
            }),
            DefaultRowViewModel(title: "Addresses info", action: { [weak self] in
                self?.coordinator?.openAddressesInfo()
            }),
        ]

        updateCurrentPromoCode()

        updateFinishedPromotionNames()

        updateAwardedPromotionNames()

        forcedDemoCardId = AppSettings.shared.forcedDemoCardId ?? ""

        $forcedDemoCardId
            .removeDuplicates()
            .sink { newValue in
                AppSettings.shared.forcedDemoCardId = newValue.nilIfEmpty
            }
            .store(in: &bag)

        fcmToken = Messaging.messaging().fcmToken ?? "none"

        updateApplicationUid()
    }

    func copyField(_ keyPath: KeyPath<EnvironmentSetupViewModel, String>) {
        let value = self[keyPath: keyPath]
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func resetApplicationUID() {
        AppSettings.shared.applicationUid = ""
        updateApplicationUid()
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
        currentPromoCode = promotionService.promoCode ?? "none"
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

    private func updateApplicationUid() {
        applicationUid = AppSettings.shared.applicationUid
    }
}
