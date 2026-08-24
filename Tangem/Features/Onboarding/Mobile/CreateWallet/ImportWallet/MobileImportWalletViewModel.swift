//
//  MobileImportWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemMobileWalletBackup
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileImportWalletViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var iCloudBackupState: ICloudBackupState = .loading

    let description = Description(
        title: Localization.hwImportExistingWallet,
        subtitle: Localization.hwImportExistingWalletDescription
    )

    let recoveryPhraseTitle = Localization.hwCloudBackupRestoreUseRecoveryPhrase

    private let backupManager: MobileWalletBackupManager

    private weak var coordinator: MobileImportWalletRoutable?

    init(coordinator: MobileImportWalletRoutable) {
        self.coordinator = coordinator
        backupManager = CommonMobileWalletBackupManager(destination: .iCloud)

        setupICloudBackupState(needsPrefetch: true)
    }
}

// MARK: - Internal methods

extension MobileImportWalletViewModel {
    func onRecoveryPhraseTap() {
        openWalletImportFlow()
    }

    func onCloseTap() {
        close()
    }
}

// MARK: - ICloudBackup state

extension MobileImportWalletViewModel {
    func setupICloudBackupState(needsPrefetch: Bool) {
        runTask(in: self) { viewModel in
            await viewModel.setup(iCloudBackupState: .loading)

            let state: ICloudBackupState
            if needsPrefetch {
                state = await viewModel.prefetchICloudBackupState()
                viewModel.logImportRequestAnalytics(state: state)
            } else {
                state = await viewModel.fetchICloudBackupState()
            }

            await viewModel.setup(iCloudBackupState: state)
        }
    }

    func prefetchICloudBackupState() async -> ICloudBackupState {
        do {
            // Per requirements, the backup prefetch may hold the button in the loading state.
            let backups = try await Task.run(withTimeout: Constants.loadingTimeout) { [backupManager] in
                try await backupManager.loadBackups()
            }

            guard backups.isNotEmpty else {
                return .notFound
            }

            let action: () -> Void = { [weak self] in
                self?.openICloudBackupImportFlow(backups)
            }
            return .enabled(action: action)

        } catch {
            let action: () -> Void = { [weak self] in
                self?.setupICloudBackupState(needsPrefetch: false)
            }
            return .enabled(action: action)
        }
    }

    func fetchICloudBackupState() async -> ICloudBackupState {
        do {
            let backups = try await backupManager.loadBackups()

            guard backups.isNotEmpty else {
                return .notFound
            }

            let action: () -> Void = { [weak self] in
                self?.openICloudBackupImportFlow(backups)
            }
            return .enabled(action: action)

        } catch {
            await presentICloudBackupErrorAlert()
            let action: () -> Void = { [weak self] in
                self?.setupICloudBackupState(needsPrefetch: false)
            }
            return .enabled(action: action)
        }
    }
}

// MARK: - Helpers

private extension MobileImportWalletViewModel {
    @MainActor
    func setup(iCloudBackupState: ICloudBackupState) {
        self.iCloudBackupState = iCloudBackupState
    }

    @MainActor
    func presentICloudBackupErrorAlert() {
        let alert = AlertBuilder.makeAlert(
            title: Localization.hwCloudBackupRestoreErrorTitle,
            message: Localization.hwCloudBackupRestoreErrorWithRecovery,
            primaryButton: .default(Text(Localization.commonOk))
        )
        alertPresenter.present(alert: alert)
    }

    func openICloudBackupImportFlow(_ backups: [MobileWalletBackup]) {
        let flow = MobileOnboardingFlow.iCloudBackupImport(backups: backups, source: .importWallet)
        let input = MobileOnboardingInput(flow: flow)
        let options = OnboardingCoordinator.Options.mobileInput(input)
        runTask(in: self) { viewModel in
            await viewModel.openOnboarding(options: options)
        }
    }

    func openWalletImportFlow() {
        let flow = MobileOnboardingFlow.walletImport(source: .importWallet)
        let input = MobileOnboardingInput(
            flow: flow,
            shouldLogOnboardingStartedAnalytics: false
        )
        let options = OnboardingCoordinator.Options.mobileInput(input)
        runTask(in: self) { viewModel in
            await viewModel.openOnboarding(options: options)
        }
    }

    func close() {
        runTask(in: self) { viewModel in
            await viewModel.closeImportWallet()
        }
    }
}

// MARK: - Routing

@MainActor
private extension MobileImportWalletViewModel {
    func openOnboarding(options: OnboardingCoordinator.Options) {
        coordinator?.closeImportWallet()
        coordinator?.openOnboarding(options: options)
    }

    func closeImportWallet() {
        coordinator?.closeImportWallet()
    }
}

// MARK: - Analytics

private extension MobileImportWalletViewModel {
    func logImportRequestAnalytics(state: ICloudBackupState) {
        let backupCloud: Analytics.ParameterValue = switch state {
        case .enabled: .available
        case .loading, .notFound: .unavailable
        }

        Analytics.log(
            .importWalletRequest,
            params: [.backupCloud: backupCloud],
            contextParams: .custom(.mobileWallet)
        )
    }
}

// MARK: - Constants

private extension MobileImportWalletViewModel {
    enum Constants {
        static let loadingTimeout: Duration = .seconds(1)
    }
}

// MARK: - Types

extension MobileImportWalletViewModel {
    struct Description {
        let title: String
        let subtitle: String
    }

    enum ICloudBackupState {
        case loading
        case enabled(action: () -> Void)
        case notFound

        var title: String {
            switch self {
            case .loading, .enabled: Localization.hwImportRestoreCloudBackup(MobileBackupConstants.iCloudServiceName)
            case .notFound: Localization.hwImportRestoreCloudBackupNotFound(MobileBackupConstants.iCloudServiceName)
            }
        }

        var isEnabled: Bool {
            switch self {
            case .enabled: true
            case .loading, .notFound: false
            }
        }

        var isLoading: Bool {
            switch self {
            case .loading: true
            case .enabled, .notFound: false
            }
        }

        var action: () -> Void {
            switch self {
            case .enabled(let action): action
            case .loading, .notFound: {}
            }
        }
    }
}
