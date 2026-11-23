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
import TangemVisa
import TangemPay
import TangemStaking
import TangemFirebaseDynamicShim
import TangemAccessibilityIdentifiers
import TangemBackendAuthenticationDebugSupport
import struct TangemUIUtils.AlertBinder

final class EnvironmentSetupViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var appSettingsTogglesViewModels: [DefaultToggleRowViewModel] = []
    @Published var pickerViewModels: [DefaultPickerRowViewModel] = []
    @Published var featureStateViewModels: [FeatureStateRowViewModel] = []
    @Published var additionalSettingsViewModels: [DefaultRowViewModel] = []
    @Published var alert: AlertBinder?

    @Published var searchText: String = ""

    var isSearching: Bool {
        !searchQueryTokens(from: searchText).isEmpty
    }

    var featureTogglesSectionTitle: String {
        guard isSearching else {
            return "Feature toggles"
        }

        return "Feature toggles (\(featureStateViewModels.count) of \(allFeatureStateViewModels.count))"
    }

    /// Demo
    @Published var forcedDemoCardId: String = ""

    // [REDACTED_TODO_COMMENT]
    @Published var surveySparrowToken: String = "ntt-84iF22PDajmervYneMW4kv"

    /// FirebaseMessaging
    @Published private(set) var fcmToken: String = ""

    /// Application UID
    @Published var applicationUid: String = ""

    @Published private(set) var walletIds: [WalletIds] = []

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let featureStorage = FeatureStorage.instance
    private weak var coordinator: EnvironmentSetupRoutable?
    private var allFeatureStateViewModels: [FeatureStateRowViewModel] = []
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
        ]

        pickerViewModels = [
            DefaultPickerRowViewModel(
                title: "Backend Authentication API type",
                options: BackendAuthenticationAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: FeatureStorage.Defaults.backendAuthenticationAPIType.rawValue,
                    get: { $0.backendAuthenticationAPIType.rawValue },
                    set: { [weak self] storage, rawValue in
                        self?.updateBackendAuthenticationAPIType(rawValue: rawValue, in: storage)
                    }
                ),
                pickerStyle: .menu
            ),
            DefaultPickerRowViewModel(
                title: "Tangem API type",
                options: TangemAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: FeatureStorage.Defaults.tangemAPIType.rawValue,
                    get: { $0.tangemAPIType.rawValue },
                    set: { $0.tangemAPIType = TangemAPIType(rawValue: $1) ?? .prod }
                ),
                pickerStyle: .menu
            ),
            DefaultPickerRowViewModel(
                title: "Express API type",
                options: ExpressAPIType.allCases.map { $0.rawValue },
                displayTitles: ExpressAPIType.allCases.map { $0.title },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: FeatureStorage.Defaults.expressAPIType.rawValue,
                    get: { $0.apiExpress.rawValue },
                    set: { $0.apiExpress = ExpressAPIType(rawValue: $1) ?? .production }
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
                ),
                pickerStyle: .menu
            ),
            DefaultPickerRowViewModel(
                title: "StakeKit staking API type",
                options: StakeKitAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: StakeKitAPIType.prod.rawValue,
                    get: { $0.stakeKitAPIType.rawValue },
                    set: { $0.stakeKitAPIType = StakeKitAPIType(rawValue: $1) ?? .prod }
                ),
                pickerStyle: .menu
            ),
            DefaultPickerRowViewModel(
                title: "YieldModule API type",
                options: YieldModuleAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: YieldModuleAPIType.prod.rawValue,
                    get: { $0.yieldModuleAPIType.rawValue },
                    set: { $0.yieldModuleAPIType = YieldModuleAPIType(rawValue: $1) ?? .prod }
                ),
                pickerStyle: .menu
            ),
            DefaultPickerRowViewModel(
                title: "Gasless Transactions API type",
                options: GaslessTransactionsAPIType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: GaslessTransactionsAPIType.prod.rawValue,
                    get: { $0.gaslessTransactionsAPIType.rawValue },
                    set: { $0.gaslessTransactionsAPIType = GaslessTransactionsAPIType(rawValue: $1) ?? .prod }
                ),
                pickerStyle: .menu
            ),
            DefaultPickerRowViewModel(
                title: "Apple Pay merchant env",
                options: ApplePayMerchantType.allCases.map { $0.rawValue },
                selection: BindingValue<String>(
                    root: featureStorage,
                    default: ApplePayMerchantType.sandbox.rawValue,
                    get: { $0.applePayMerchantType.rawValue },
                    set: { $0.applePayMerchantType = ApplePayMerchantType(rawValue: $1) ?? .sandbox }
                ),
                pickerStyle: .menu
            ),
        ]

        allFeatureStateViewModels = Feature.allCases.reversed().map { feature in
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

        $searchText
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self else { return }

                featureStateViewModels = filterFeatureStateViewModels(searchText: searchText)
            }
            .store(in: &bag)

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
            DefaultRowViewModel(
                title: "Addresses info",
                accessibilityIdentifier: CommonUIAccessibilityIdentifiers.addressesInfoButton,
                action: { [weak self] in
                    self?.coordinator?.openAddressesInfo()
                }
            ),
        ] + designSystemDemoRows + [
            DefaultRowViewModel(title: "Stories V2 Demo", action: { [weak self] in
                self?.coordinator?.openStoriesV2Demo()
            }),
            DefaultRowViewModel(title: "Silent Push Tester", action: { [weak self] in
                self?.coordinator?.openSilentPushTester()
            }),
            DefaultRowViewModel(title: "Backend Auth", action: { [weak self] in
                self?.coordinator?.openBackendAuthentication()
            }),
            DefaultRowViewModel(title: "Drop app database", action: { [weak self] in
                self?.showDropAppDatabaseAlert()
            }),
        ]

        forcedDemoCardId = AppSettings.shared.forcedDemoCardId ?? ""

        $forcedDemoCardId
            .removeDuplicates()
            .sink { newValue in
                AppSettings.shared.forcedDemoCardId = newValue.nilIfEmpty
            }
            .store(in: &bag)

        fcmToken = Messaging.messaging().fcmToken ?? "none"

        updateApplicationUid()
        updateWalletIds()
    }

    func copy(_ value: String) {
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func updateWalletIds() {
        walletIds = userWalletRepository.models.map {
            WalletIds(id: $0.userWalletId.stringValue, name: $0.name, hash: $0.userWalletId.hashedStringValue)
        }
    }

    func resetApplicationUID() {
        AppSettings.shared.applicationUid = ""
        updateApplicationUid()
    }

    func showDropAppDatabaseAlert() {
        let alert = Alert(
            title: Text("Drop the app database on the next launch?"),
            primaryButton: .destructive(Text("Yes"), action: {
                AppDatabaseDropUtil.scheduleDrop()
            }),
            secondaryButton: .cancel(Text("No"))
        )
        self.alert = AlertBinder(alert: alert)
    }

    func showExitAlert(reason: String? = nil) {
        let alert = Alert(
            title: Text("Are you sure you want to exit the app?"),
            message: reason.map { Text($0) },
            primaryButton: .destructive(Text("Exit"), action: { exit(1) }),
            secondaryButton: .cancel()
        )
        self.alert = AlertBinder(alert: alert)
    }

    private func updateBackendAuthenticationAPIType(rawValue: String, in storage: FeatureStorage) {
        guard
            let apiType = BackendAuthenticationAPIType(rawValue: rawValue),
            apiType != storage.backendAuthenticationAPIType
        else {
            return
        }

        storage.backendAuthenticationAPIType = apiType

        Task { @MainActor [weak self] in
            await BackendAuthenticationDebugAssembly.resetAll()
            self?.showExitAlert(reason: "Restart is required to apply the changes.")
        }
    }

    private func filterFeatureStateViewModels(searchText: String) -> [FeatureStateRowViewModel] {
        let tokens = searchQueryTokens(from: searchText)

        guard !tokens.isEmpty else {
            return allFeatureStateViewModels
        }

        return allFeatureStateViewModels.filter { viewModel in
            let haystack = normalized("\(viewModel.feature.name) \(viewModel.feature.rawValue)")
            return tokens.allSatisfy { haystack.contains($0) }
        }
    }

    /// Both the toggle name and the ticket key are written with `_` and `-` separators,
    /// so the query is matched word by word instead of as a raw substring.
    private func searchQueryTokens(from searchText: String) -> [String] {
        normalized(searchText).split(separator: " ").map(String.init)
    }

    private func normalized(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    private var designSystemDemoRows: [DefaultRowViewModel] {
        #if INTERNAL || DEBUG
        return [
            DefaultRowViewModel(title: "Design System Demo", action: { [weak self] in
                self?.coordinator?.openDesignSystemDemo()
            }),
        ]
        #else
        return []
        #endif
    }

    private func updateApplicationUid() {
        applicationUid = AppSettings.shared.applicationUid
    }

    // [REDACTED_TODO_COMMENT]
    func handleSurveySparrowDemoClassicButtonTapped() {
        coordinator?.openSparrowSurveyClassicDemo(withToken: surveySparrowToken)
    }
}

// MARK: - Wallet ids

extension EnvironmentSetupViewModel {
    struct WalletIds: Identifiable {
        let id: String
        let name: String
        let hash: String
    }
}
