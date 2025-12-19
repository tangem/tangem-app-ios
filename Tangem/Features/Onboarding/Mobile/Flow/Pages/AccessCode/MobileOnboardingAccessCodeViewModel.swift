//
//  MobileOnboardingAccessCodeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import LocalAuthentication
import TangemFoundation
import TangemAssets
import TangemLocalization
import TangemUIUtils
import TangemMobileWalletSdk
import class TangemSdk.BiometricsUtil

final class MobileOnboardingAccessCodeViewModel: ObservableObject {
    @Published private(set) var state: State = .accessCode

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private var accessCode: String = ""
    @Published private var confirmAccessCode: String = ""

    @Published var alert: AlertBinder?

    let codeLength: Int = 6

    var leadingNavBarItem: MobileOnboardingFlowNavBarAction? {
        makeLeadingNavBarItem()
    }

    var trailingNavBarItem: MobileOnboardingFlowNavBarAction? {
        makeTrailingNavBarItem()
    }

    var code: Binding<String> {
        Binding(
            get: {
                switch self.state {
                case .accessCode:
                    self.accessCode
                case .confirmAccessCode:
                    self.confirmAccessCode
                }
            },
            set: { newValue in
                DispatchQueue.main.async {
                    switch self.state {
                    case .accessCode:
                        self.accessCode = newValue
                    case .confirmAccessCode:
                        self.confirmAccessCode = newValue
                    }
                }
            }
        )
    }

    var infoItem: InfoItem {
        switch state {
        case .accessCode:
            InfoItem(
                title: Localization.accessCodeCreateTitle,
                description: Localization.accessCodeCreateDescription("\(codeLength)")
            )
        case .confirmAccessCode:
            InfoItem(
                title: Localization.accessCodeConfirmTitle,
                description: Localization.accessCodeConfirmDescription
            )
        }
    }

    var isPinSecured: Bool {
        switch state {
        case .accessCode:
            false
        case .confirmAccessCode:
            true
        }
    }

    var pinColor: Color {
        switch state {
        case .accessCode:
            return Colors.Text.primary1
        case .confirmAccessCode where confirmAccessCode.count == codeLength:
            return confirmAccessCode == accessCode ? Colors.Text.accent : Colors.Text.warning
        case .confirmAccessCode:
            return Colors.Text.primary1
        }
    }

    private var analyticsContextParams: Analytics.ContextParams {
        guard let userWalletModel = delegate?.getUserWalletModel() else {
            return .empty
        }
        return .custom(userWalletModel.analyticsContextData)
    }

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let accessCodeValidator = MobileOnboardingAccessCodeValidator()

    private let mode: Mode
    private let source: MobileOnboardingFlowSource
    private weak var delegate: MobileOnboardingAccessCodeDelegate?

    private var appearedStates: Set<State> = []
    private var appearedSubscription: AnyCancellable?

    private var bag = Set<AnyCancellable>()

    init(
        mode: Mode,
        source: MobileOnboardingFlowSource,
        delegate: MobileOnboardingAccessCodeDelegate
    ) {
        self.mode = mode
        self.source = source
        self.delegate = delegate
        bind()
    }

    deinit {
        AppLogger.debug("MobileOnboardingAccessCodeViewModel deinit")
    }
}

// MARK: - Internal methods

extension MobileOnboardingAccessCodeViewModel {
    func onFirstAppear() {
        appearedSubscription = $state
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.handleAppeared(state: state)
            }
    }
}

// MARK: - Private methods

private extension MobileOnboardingAccessCodeViewModel {
    func bind() {
        $accessCode
            .dropFirst()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .sink { [weak self] code in
                self?.check(accessCode: code)
            }
            .store(in: &bag)

        $confirmAccessCode
            .dropFirst()
            .sink { [weak self] code in
                self?.check(confirmAccessCode: code)
            }
            .store(in: &bag)
    }

    func check(accessCode: String) {
        guard accessCode.count == codeLength else {
            return
        }

        logAccessCodeEnteredAnalytics()

        guard accessCodeValidator.validate(accessCode: accessCode) else {
            alert = makeAccessCodeValidationAlert()
            return
        }

        setup(state: .confirmAccessCode)
    }

    func check(confirmAccessCode: String) {
        guard
            confirmAccessCode.count == codeLength,
            confirmAccessCode == accessCode
        else {
            return
        }

        logAccessCodeReEnteredAnalytics()
        handleConfirmed(accessCode: accessCode)
    }

    func handleConfirmed(accessCode: String) {
        guard let userWalletModel = delegate?.getUserWalletModel(),
              let userWalletIdSeed = userWalletModel.config.userWalletIdSeed else {
            return
        }

        let userWalletId = userWalletModel.userWalletId

        runTask(in: self) { viewModel in
            do {
                let context = switch viewModel.mode {
                case .create:
                    try viewModel.mobileWalletSdk.validate(auth: .none, for: userWalletId)
                case .change(let context):
                    context
                }

                let isBiometricsAvailable = await viewModel.isBiometricsAvailable()
                let requireAccessCodes = await AppSettings.shared.requireAccessCodes

                try viewModel.mobileWalletSdk.updateAccessCode(
                    accessCode,
                    enableBiometrics: isBiometricsAvailable && !requireAccessCodes,
                    seedKey: userWalletIdSeed,
                    context: context
                )

                userWalletModel.update(type: .accessCodeDidSet)
                AppLogger.info("AccessCode update was successful, biometrics enabled: \(isBiometricsAvailable)")
                await viewModel.onAccessCodeComplete()

            } catch {
                AppLogger.error("AccessCode setup failed:", error: error)
                await runOnMain {
                    viewModel.alert = error.alertBinder
                }
            }
        }
    }

    func handleAppeared(state: State) {
        guard !appearedStates.contains(state) else {
            return
        }

        appearedStates.insert(state)

        switch state {
        case .accessCode:
            logCreateAccessCodeAppearedAnalytics()
        case .confirmAccessCode:
            logConfirmAccessCodeAppearedAnalytics()
        }
    }

    func isBiometricsAvailable() async -> Bool {
        if BiometricsUtil.isAvailable {
            do {
                if await !AppSettings.shared.askedToSaveUserWallets {
                    _ = try await requestBiometrics()
                    return true
                } else {
                    return await AppSettings.shared.useBiometricAuthentication
                }
            } catch {
                return false
            }
        }

        return false
    }

    func requestBiometrics() async throws -> LAContext {
        await MainActor.run {
            AppSettings.shared.askedToSaveUserWallets = true
        }

        let context = try await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)

        await MainActor.run {
            AppSettings.shared.useBiometricAuthentication = true
            AppSettings.shared.requireAccessCodes = false
        }

        userWalletRepository.onBiometricsChanged(enabled: true)
        AppLogger.info("AccessCode biometrics request was successful")

        return context
    }

    func setup(state: State) {
        self.state = state
    }

    func resetState() {
        accessCode = ""
        confirmAccessCode = ""
        setup(state: .accessCode)
    }
}

// MARK: - Private methods

private extension MobileOnboardingAccessCodeViewModel {
    @MainActor
    func onAccessCodeComplete() {
        delegate?.didCompleteAccessCode()
    }
}

// MARK: - NavBar

private extension MobileOnboardingAccessCodeViewModel {
    func makeLeadingNavBarItem() -> MobileOnboardingFlowNavBarAction? {
        let item: MobileOnboardingFlowNavBarAction?

        switch state {
        case .accessCode:
            item = nil
        case .confirmAccessCode:
            let backHandler = weakify(self, forFunction: MobileOnboardingAccessCodeViewModel.onBackTap)
            item = .back(handler: backHandler)
        }

        return item
    }

    func makeTrailingNavBarItem() -> MobileOnboardingFlowNavBarAction? {
        switch mode {
        case .create(let canSkip):
            return canSkip ? .skip(handler: weakify(self, forFunction: MobileOnboardingAccessCodeViewModel.onSkipTap)) : nil
        case .change:
            return nil
        }
    }

    func onSkipTap() {
        alert = makeSkipAlert()
    }

    func onBackTap() {
        resetState()
    }
}

// MARK: - Alert makers

private extension MobileOnboardingAccessCodeViewModel {
    func makeSkipAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.accessCodeAlertSkipTitle,
            message: Localization.accessCodeAlertSkipDescription,
            with: .init(
                primaryButton: .default(
                    Text(Localization.accessCodeAlertSkipOk),
                    action: weakify(self, forFunction: MobileOnboardingAccessCodeViewModel.onSkipOkTap)
                ),
                secondaryButton: .cancel()
            )
        )
    }

    func makeAccessCodeValidationAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.accessCodeAlertValidationTitle,
            message: Localization.accessCodeAlertValidationDescription,
            with: .init(
                primaryButton: .destructive(
                    Text(Localization.accessCodeAlertValidationOk),
                    action: weakify(self, forFunction: MobileOnboardingAccessCodeViewModel.onAccessCodeValidationOkTap)
                ),
                secondaryButton: .default(
                    Text(Localization.accessCodeAlertValidationCancel),
                    action: {}
                ),
            )
        )
    }

    func onSkipOkTap() {
        logSkipTapAnalytics()

        guard let userWalletModel = delegate?.getUserWalletModel() else {
            return
        }

        userWalletModel.update(type: .accessCodeDidSkip)
        runTask(in: self) { viewModel in
            await viewModel.onAccessCodeComplete()
        }
    }

    func onAccessCodeValidationOkTap() {
        setup(state: .confirmAccessCode)
    }
}

// MARK: - Analytics

private extension MobileOnboardingAccessCodeViewModel {
    func logCreateAccessCodeAppearedAnalytics() {
        Analytics.log(
            .walletSettingsCreateAccessCode,
            params: source.analyticsParams,
            contextParams: analyticsContextParams
        )
    }

    func logConfirmAccessCodeAppearedAnalytics() {
        Analytics.log(
            .walletSettingsConfirmAccessCode,
            params: source.analyticsParams,
            contextParams: analyticsContextParams
        )
    }

    func logAccessCodeEnteredAnalytics() {
        Analytics.log(.accessCodeEntered, contextParams: analyticsContextParams)
    }

    func logAccessCodeReEnteredAnalytics() {
        Analytics.log(.accessCodeReEntered, contextParams: analyticsContextParams)
    }

    func logSkipTapAnalytics() {
        Analytics.log(.backupAccessCodeSkipped, contextParams: analyticsContextParams)
    }
}

// MARK: - Types

extension MobileOnboardingAccessCodeViewModel {
    enum Mode {
        case create(canSkip: Bool)
        case change(MobileWalletContext)
    }

    enum State {
        case accessCode
        case confirmAccessCode
    }

    struct InfoItem {
        let title: String
        let description: String
    }
}
