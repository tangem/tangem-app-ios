//
//  UITestsConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

#if DEBUG
import TangemFoundation
import UIKit

/// Result of UI test configuration containing information about created mock wallets.
struct UITestsConfigurationResult {
    let mockWalletsCreated: Bool
}

/// Configures the app for UI testing based on launch arguments and environment variables.
enum UITestsConfigurator {
    /// Configures the app for UI testing.
    /// - Returns: Configuration result with information about mock wallets
    static func configure() -> UITestsConfigurationResult {
        guard AppEnvironment.current.isUITest else {
            return UITestsConfigurationResult(mockWalletsCreated: false)
        }

        let arguments = ProcessInfo.processInfo.arguments

        configureTermsOfService(arguments: arguments)
        configureCachedFiles(arguments: arguments)
        configureMobileWallet(arguments: arguments)

        let mockWalletsCreated = configureMockRepository(arguments: arguments)

        UIView.setAnimationsEnabled(false)

        return UITestsConfigurationResult(mockWalletsCreated: mockWalletsCreated)
    }

    // MARK: - Private

    private static func configureTermsOfService(arguments: [String]) {
        if arguments.contains("-uitest-skip-tos") {
            AppSettings.shared.termsOfServicesAccepted = ["https://tangem.com/tangem_tos.html"]
        } else {
            AppSettings.shared.termsOfServicesAccepted = []
        }
    }

    private static func configureCachedFiles(arguments: [String]) {
        if arguments.contains("-uitest-clear-storage") {
            UITestsStorageCleaner.clearCachedFiles()
        }
    }

    private static func configureMobileWallet(arguments: [String]) {
        if arguments.contains("-uitest-disable-mobile-wallet") {
            FeatureStorage.instance.availableFeatures[.mobileWallet] = .off
        } else {
            FeatureStorage.instance.availableFeatures[.mobileWallet] = .on
        }
    }

    /// Configures mock wallet repository for UI tests.
    /// - Returns: true if mock wallets were created
    private static func configureMockRepository(arguments: [String]) -> Bool {
        guard arguments.contains("-uitest-mock-repository") else {
            if arguments.contains("-uitest-clear-storage") {
                UITestsStorageCleaner.clearWalletData()
            }
            return false
        }

        let mnemonics = generateMnemonicsFromSeeds()

        AppSettings.shared.saveUserWallets = true

        if arguments.contains("-uitest-clear-storage") {
            UserWalletDataStorage().clear()
            UITestsStorageCleaner.clearWalletConnectFiles()
        }

        if !mnemonics.isEmpty {
            KeychainCleaner.cleanAllData()
        }

        let mockRepository = MockUserWalletRepository(mnemonics: mnemonics)
        InjectedValues[\.userWalletRepository] = mockRepository

        if !mnemonics.isEmpty {
            mockRepository.waitForWalletsCreation()
            return true
        }

        return false
    }

    private static func generateMnemonicsFromSeeds() -> [String] {
        let environment = ProcessInfo.processInfo.environment

        guard let seedsJSON = environment["UITEST_MOCK_WALLET_SEEDS"],
              let seedsData = seedsJSON.data(using: .utf8),
              let seeds = try? JSONDecoder().decode([String].self, from: seedsData)
        else {
            return []
        }

        return seeds.compactMap { seed in
            do {
                return try DeterministicMnemonicGenerator.generateMnemonic(from: seed)
            } catch {
                AppLogger.error("Failed to generate mnemonic for seed: \(seed)", error: error)
                return nil
            }
        }
    }
}
#endif
