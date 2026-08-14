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

    @Published private(set) var passwordMatching: PasswordMatching = .none
    @Published private(set) var isPasswordSecured: Bool = true
    @Published private(set) var isImporting: Bool = false

    @Published var passwordText: String = .empty
    @Published var isPasswordResponder: Bool?

    @Published private var backup: MobileWalletBackup?

    let navigationTitle = "Enter password"
    let infoTitle = "Restore wallet"

    var infoDescription: String {
        makeInfoDescription()
    }

    let actionTitle = "Restore"

    var isActionEnabled: Bool {
        passwordText.isNotEmpty
    }

    private let passwordNotMatchedSubject = PassthroughSubject<Void, Never>()

    private let dateFormatterCache = NSCacheWrapper<String, DateFormatter>()
    private let dateFormat = "MMMM d yyyy, h:mm a"

    private lazy var backupManager = CommonMobileWalletBackupManager(
        destination: .iCloud
    )

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
    func onPasswordSecurityTap() {
        isPasswordSecured.toggle()
    }

    func onActionTap() {
        runTask(in: self) { viewModel in
            await viewModel.importWallet()
        }
    }

    func onBackTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }

    func onAppear() {
        isPasswordResponder = true
        backup = dataSource?.getBackup()
    }

    func onDisappear() {
        initialSetup()
    }
}

// MARK: - Private methods

private extension MobileOnboardingImportICloudBackupViewModel {
    func bind() {
        let passwordInputMatchingPublisher = $passwordText
            .map { password -> PasswordMatching in
                password.isEmpty ? .none : .notDetermined
            }

        let failedAttemptMatchingPublisher = passwordNotMatchedSubject.map { PasswordMatching.notMatched }

        passwordInputMatchingPublisher
            .merge(with: failedAttemptMatchingPublisher)
            .receiveOnMain()
            .assign(to: &$passwordMatching)
    }

    func makeInfoDescription() -> String {
        let walletName = backup?.metadata.walletName ?? .empty
        let backupDate = backup?.metadata.createdAt.map { dateFormatter().string(from: $0) } ?? .empty
        return "You’re restoring “\(walletName)” from an iCloud backup created on \(backupDate). Enter the encryption password to continue."
    }

    func sendPasswordNotMatched() {
        passwordNotMatchedSubject.send()
    }

    func initialSetup() {
        passwordText = .empty
        isPasswordSecured = true
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

    @MainActor
    func setup(isImporting: Bool) {
        self.isImporting = isImporting
    }
}

// MARK: - Import flow

private extension MobileOnboardingImportICloudBackupViewModel {
    func importWallet() async {
        guard let backup else {
            await showErrorAlert()
            return
        }

        do {
            await setup(isImporting: true)

            let backupPayload = try await backupManager.importBackup(backup, password: passwordText)
            let mnemonic = try Mnemonic(with: backupPayload.mnemonicWords.joined(separator: " "))

            let userWalletModel = try await creationUtil.makeImportedModel(
                mnemonic: mnemonic,
                passphrase: backupPayload.passphrase,
                hasMnemonicBackup: false,
                hasICloudBackup: true
            )

            AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: userWalletModel.userWalletId)
            try userWalletRepository.add(userWalletModel: userWalletModel)

            await setup(isImporting: false)
            await didImportBackup(userWalletModel: userWalletModel)

        } catch {
            await setup(isImporting: false)

            switch error {
            case WalletBackupCryptoError.invalidPassword:
                sendPasswordNotMatched()
            default:
                await showErrorAlert()
            }

            AppLogger.error("Failed to import wallet from iCloud backup", error: error)
        }
    }
}

// MARK: - Alerts

@MainActor
private extension MobileOnboardingImportICloudBackupViewModel {
    func showErrorAlert() {
        let alert = AlertBuilder.makeAlert(
            title: "Something went wrong",
            message: "Please try again later or import your recovery phrase.",
            primaryButton: .default(Text("OK"))
        )
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
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
    enum PasswordMatching {
        case none
        case notDetermined
        case notMatched

        var description: String? {
            switch self {
            case .none, .notDetermined: nil
            case .notMatched: "Wrong password"
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
