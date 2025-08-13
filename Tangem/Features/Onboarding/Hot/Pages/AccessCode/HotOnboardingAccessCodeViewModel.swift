//
//  HotOnboardingAccessCodeViewModel.swift
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
import TangemHotSdk
import class TangemSdk.BiometricsUtil

final class HotOnboardingAccessCodeViewModel: ObservableObject {
    @Published private(set) var state: State = .accessCode

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private var accessCode: String = ""
    @Published private var confirmAccessCode: String = ""

    @Published var alert: AlertBinder?

    let codeLength: Int = 6

    var leadingBavBarItem: HotOnboardingFlowNavBarAction? {
        makeLeadingNavBarItem()
    }

    var trailingBavBarItem: HotOnboardingFlowNavBarAction? {
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

    private lazy var hotSdk: HotSdk = CommonHotSdk()

    private let mode: Mode
    private weak var delegate: HotOnboardingAccessCodeDelegate?

    private var bag = Set<AnyCancellable>()

    init(mode: Mode, delegate: HotOnboardingAccessCodeDelegate) {
        self.mode = mode
        self.delegate = delegate
        bind()
    }
}

// MARK: - Private methods

private extension HotOnboardingAccessCodeViewModel {
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
        state = .confirmAccessCode
    }

    func check(confirmAccessCode: String) {
        guard
            confirmAccessCode.count == codeLength,
            confirmAccessCode == accessCode
        else {
            return
        }

        handleConfirmed(accessCode: accessCode)
    }

    func handleConfirmed(accessCode: String) {
        guard let userWalletModel = delegate?.getUserWalletModel() else {
            return
        }

        runTask(in: self) { viewModel in
            do {
                let context = switch viewModel.mode {
                case .create:
                    try viewModel.hotSdk.validate(auth: .none, for: userWalletModel.userWalletId)
                case .change(let context):
                    context
                }

                try viewModel.hotSdk.updateAccessCode(viewModel.accessCode, context: context)
                userWalletModel.update(type: .accessCodeDidSet)
                AppLogger.info("AccessCode update was successful")

                await viewModel.requestBiometricsIfNeeded(userWalletId: userWalletModel.userWalletId, accessCode: accessCode)
                await viewModel.onAccessCodeComplete()

            } catch {
                AppLogger.error("AccessCode setup failed:", error: error)
                await runOnMain {
                    viewModel.alert = error.alertBinder
                }
            }
        }
    }

    func requestBiometricsIfNeeded(userWalletId: UserWalletId, accessCode: String) async {
        // [REDACTED_TODO_COMMENT]
        let isBiometricsEnabled = true

        if BiometricsUtil.isAvailable, isBiometricsEnabled {
            do {
                let context: MobileWalletContext
                if !AppSettings.shared.askedToSaveUserWallets {
                    let laContext = try await requestBiometrics()
                    context = try hotSdk.validate(auth: .biometrics(context: laContext), for: userWalletId)
                } else {
                    context = try hotSdk.validate(auth: .accessCode(accessCode), for: userWalletId)
                }

                try hotSdk.enableBiometrics(context: context)
                AppLogger.info("AccessCode enable biometrics was successful")

            } catch {
                AppLogger.error("AccessCode biometrics request failed:", error: error)
            }
        }
    }

    func requestBiometrics() async throws -> LAContext {
        AppSettings.shared.askedToSaveUserWallets = true

        let context = try await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)

        userWalletRepository.onBiometricsChanged(enabled: true)
        AppLogger.info("AccessCode biometrics request was successful")

        return context
    }

    func resetState() {
        accessCode = ""
        confirmAccessCode = ""
        state = .accessCode
    }
}

// MARK: - Private methods

private extension HotOnboardingAccessCodeViewModel {
    @MainActor
    func onAccessCodeComplete() {
        delegate?.didCompleteAccessCode()
    }
}

// MARK: - NavBar

private extension HotOnboardingAccessCodeViewModel {
    func makeLeadingNavBarItem() -> HotOnboardingFlowNavBarAction? {
        let item: HotOnboardingFlowNavBarAction?

        switch state {
        case .accessCode:
            item = nil
        case .confirmAccessCode:
            let backHandler = weakify(self, forFunction: HotOnboardingAccessCodeViewModel.onBackTap)
            item = .back(handler: backHandler)
        }

        return item
    }

    func makeTrailingNavBarItem() -> HotOnboardingFlowNavBarAction? {
        switch mode {
        case .create:
            return .skip(handler: weakify(self, forFunction: HotOnboardingAccessCodeViewModel.onSkipTap))
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

private extension HotOnboardingAccessCodeViewModel {
    func makeSkipAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.accessCodeAlertSkipTitle,
            message: Localization.accessCodeAlertSkipDescription,
            with: .withPrimaryCancelButton(
                secondaryTitle: Localization.accessCodeAlertSkipOk,
                secondaryAction: weakify(self, forFunction: HotOnboardingAccessCodeViewModel.onSkipOkTap)
            )
        )
    }

    func onSkipOkTap() {
        guard let userWalletModel = delegate?.getUserWalletModel() else {
            return
        }
        HotAccessCodeSkipHelper.append(userWalletId: userWalletModel.userWalletId)
        runTask(in: self) { viewModel in
            await viewModel.onAccessCodeComplete()
        }
    }
}

// MARK: - Types

extension HotOnboardingAccessCodeViewModel {
    enum Mode {
        case create
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
