//
//  MobileOnboardingImportICloudBackupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemFoundation
import TangemSdk
import TangemMobileWalletBackup
import TangemAssets
import TangemLocalization
import TangemUIUtils

final class MobileOnboardingImportICloudBackupViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var state: State = .password
    @Published private(set) var passwordMatching: PasswordMatching = .none
    @Published private(set) var isInputSecured: Bool = true
    @Published private(set) var isProcessing: Bool = false

    @Published var inputText: String = .empty
    @Published var isInputResponder: Bool?

    @Published private var backup: MobileWalletBackup?

    let navigationTitle = Localization.hwCloudBackupRestorePasswordNavtitle

    var info: Info {
        Info(
            title: makeInfoTitle(),
            description: makeInfoDescription()
        )
    }

    var inputTitle: String {
        switch state {
        case .password: Localization.hwCloudBackupPasswordHint
        case .passphrase: Localization.commonPassphrase
        }
    }

    let actionTitle = Localization.hwCloudBackupRestorePasswordButton

    var isActionEnabled: Bool {
        inputText.isNotEmpty
    }

    private let passwordNotMatchedSubject = PassthroughSubject<Void, Never>()

    private let dateFormatterCache = NSCacheWrapper<String, DateFormatter>()
    private let dateFormat = "MMMM d yyyy, h:mm a"

    private lazy var backupManager = CommonMobileWalletBackupManager(
        destination: .iCloud
    )

    private var analyticsParams: [Analytics.ParameterKey: String] {
        guard let backup else {
            return [:]
        }

        let walletIdData = Data(hexString: backup.metadata.walletId)
        let walletId = UserWalletId(value: walletIdData)
        return [.userWalletId: walletId.hashedStringValue]
    }

    private let creationUtil = MobileCreationUtil()

    private weak var dataSource: MobileOnboardingImportICloudBackupDataSource?
    private weak var delegate: MobileOnboardingImportICloudBackupDelegate?

    init(
        dataSource: MobileOnboardingImportICloudBackupDataSource,
        delegate: MobileOnboardingImportICloudBackupDelegate
    ) {
        self.dataSource = dataSource
        self.delegate = delegate
        bind()
    }
}

// MARK: - Internal methods

extension MobileOnboardingImportICloudBackupViewModel {
    func onInputSecurityTap() {
        isInputSecured.toggle()
    }

    func onActionTap() {
        runTask(in: self) { viewModel in
            let input = viewModel.inputText

            switch viewModel.state {
            case .password:
                await viewModel.importFlow(password: input)
            case .passphrase(let mnemonicWords):
                await viewModel.createFlow(mnemonicWords: mnemonicWords, passphrase: input)
            }
        }
    }

    func onBackTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }

    func onAppear() {
        initialSetup()
    }

    func onDisappear() {
        runTask(in: self) { viewModel in
            await viewModel.eraseState()
        }
    }
}

// MARK: - Private methods

private extension MobileOnboardingImportICloudBackupViewModel {
    func bind() {
        let passwordInputMatchingPublisher = $inputText
            .map { password -> PasswordMatching in
                password.isEmpty ? .none : .notDetermined
            }

        let failedAttemptMatchingPublisher = passwordNotMatchedSubject.map { PasswordMatching.notMatched }

        passwordInputMatchingPublisher
            .merge(with: failedAttemptMatchingPublisher)
            .receiveOnMain()
            .assign(to: &$passwordMatching)
    }

    func sendPasswordNotMatched() {
        passwordNotMatchedSubject.send()
    }

    func initialSetup() {
        isInputResponder = true
        backup = dataSource?.getBackup()
        logPasswordScreenAnalytics()
    }

    func dateFormatter() -> DateFormatter {
        if let formatter = dateFormatterCache.value(forKey: dateFormat) {
            return formatter
        } else {
            let formatter = DateFormatter(dateFormat: dateFormat)
            dateFormatterCache.setValue(formatter, forKey: dateFormat)
            return formatter
        }
    }
}

// MARK: - Import flow

private extension MobileOnboardingImportICloudBackupViewModel {
    func importFlow(password: String) async {
        do {
            await setupIsProcessing(true)
            let backupPayload = try await importWallet(password: password)

            let mnemonicWords = backupPayload.mnemonicWords
            if backupPayload.requiresPassphrase {
                await setupPassphraseState(mnemonicWords: mnemonicWords)
            } else {
                await createFlow(mnemonicWords: mnemonicWords, passphrase: .empty)
            }

            await setupIsProcessing(false)

        } catch {
            await setupIsProcessing(false)

            switch error {
            case WalletBackupCryptoError.invalidPassword:
                logWrongPasswordAnalytics()
                sendPasswordNotMatched()
            default:
                logImportErrorAnalytics(error)
                await showErrorAlert()
            }

            AppLogger.error("Failed to import wallet from iCloud backup", error: error)
        }
    }

    func createFlow(mnemonicWords: [String], passphrase: String) async {
        do {
            await setupIsProcessing(true)
            let userWalletModel = try await createWallet(mnemonicWords: mnemonicWords, passphrase: passphrase)
            try await addWallet(userWalletModel: userWalletModel)
            await setupIsProcessing(false)

            await didImportBackup(userWalletModel: userWalletModel)

        } catch {
            await setupIsProcessing(false)

            logImportErrorAnalytics(error)
            await showErrorAlert()

            AppLogger.error("Failed to create wallet from iCloud backup", error: error)
        }
    }

    func importWallet(password: String) async throws -> WalletBackupPayload {
        guard let backup else {
            throw ImportError.backupNotFound
        }
        return try await backupManager.importBackup(backup, password: password)
    }

    func createWallet(mnemonicWords: [String], passphrase: String) async throws -> UserWalletModel {
        let mnemonic = try Mnemonic(with: mnemonicWords.joined(separator: " "))
        return try await creationUtil.makeImportedModel(
            mnemonic: mnemonic,
            passphrase: passphrase,
            hasMnemonicBackup: false,
            hasICloudBackup: true
        )
    }

    func addWallet(userWalletModel: UserWalletModel) async throws {
        AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: userWalletModel.userWalletId)
        try userWalletRepository.add(userWalletModel: userWalletModel)
    }
}

// MARK: - States

@MainActor
private extension MobileOnboardingImportICloudBackupViewModel {
    func setupPassphraseState(mnemonicWords: [String]) {
        state = .passphrase(mnemonicWords: mnemonicWords)
        eraseInput()
    }

    func setupIsProcessing(_ isProcessing: Bool) {
        self.isProcessing = isProcessing
    }

    func eraseState() {
        state = .password
        eraseInput()
    }

    func eraseInput() {
        inputText = .empty
    }
}

// MARK: - Helpers

private extension MobileOnboardingImportICloudBackupViewModel {
    func makeInfoTitle() -> String {
        switch state {
        case .password: Localization.hwCloudBackupRestorePasswordTitle
        case .passphrase: Localization.hwCloudBackupRestorePassphraseTitle
        }
    }

    func makeInfoDescription() -> String {
        switch state {
        case .password:
            let walletName = backup?.metadata.walletName ?? .empty
            let backupDate = backup?.metadata.createdAt.map { dateFormatter().string(from: $0) } ?? .empty
            return Localization.hwCloudBackupRestorePasswordDescription(walletName, MobileBackupConstants.iCloudServiceName, backupDate)
        case .passphrase:
            return Localization.hwCloudBackupRestorePassphraseDescription
        }
    }
}

// MARK: - Analytics

private extension MobileOnboardingImportICloudBackupViewModel {
    func logPasswordScreenAnalytics() {
        Analytics.log(
            event: .enterCloudBackupPasswordScreen,
            params: analyticsParams,
            contextParams: .custom(.mobileWallet)
        )
    }

    func logImportErrorAnalytics(_ error: Error) {
        var params = MobileBackupStatusUtil.errorAnalyticsParams(error)
        params.enrich(with: analyticsParams)

        Analytics.log(
            event: .importCloudBackupError,
            params: params,
            contextParams: .custom(.mobileWallet)
        )
    }

    func logWrongPasswordAnalytics() {
        Analytics.log(
            event: .wrongCloudBackupPassword,
            params: analyticsParams,
            contextParams: .custom(.mobileWallet)
        )
    }
}

// MARK: - Alerts

@MainActor
private extension MobileOnboardingImportICloudBackupViewModel {
    func showErrorAlert() {
        let alert = AlertBuilder.makeAlert(
            title: Localization.hwCloudBackupRestoreErrorTitle,
            message: Localization.hwCloudBackupRestoreErrorWithRecovery,
            primaryButton: .default(Text(Localization.commonOk))
        )
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }

    enum ImportError: Error {
        case backupNotFound
    }
}

// MARK: - Routing

@MainActor
private extension MobileOnboardingImportICloudBackupViewModel {
    func close() {
        delegate?.onBackupClose()
    }

    func didImportBackup(userWalletModel: UserWalletModel) {
        delegate?.didImportBackup(userWalletModel: userWalletModel)
    }
}

// MARK: - Types

extension MobileOnboardingImportICloudBackupViewModel {
    enum State {
        case password
        case passphrase(mnemonicWords: [String])
    }

    struct Info {
        let title: String
        let description: String
    }

    enum PasswordMatching {
        case none
        case notDetermined
        case notMatched

        var description: String? {
            switch self {
            case .none, .notDetermined: nil
            case .notMatched: Localization.hwCloudBackupRestoreWrongPassword
            }
        }

        var color: Color {
            switch self {
            case .none: DesignSystem.Color.borderBrand
            case .notDetermined: DesignSystem.Color.borderTertiary
            case .notMatched: DesignSystem.Color.borderStatusError
            }
        }
    }
}
