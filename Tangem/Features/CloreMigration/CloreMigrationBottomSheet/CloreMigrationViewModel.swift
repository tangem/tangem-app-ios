//
//  CloreMigrationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemUI
import UIKit
import TangemLocalization

final class CloreMigrationViewModel: ObservableObject {
    @Injected(\.floatingSheetPresenter) var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var message: String = "" {
        didSet {
            if message != oldValue {
                signature = ""
            }
        }
    }

    @Published var signature: String = ""

    private let claimPortalURL = URL(string: "https://claim-portal.clore.ai")
    private let userWalletId: UserWalletId
    private let accountId: String?
    private let tokenItem: TokenItem
    private weak var coordinator: (any CloreMigrationRoutable)?

    init(
        userWalletId: UserWalletId,
        accountId: String?,
        tokenItem: TokenItem,
        coordinator: any CloreMigrationRoutable
    ) {
        self.userWalletId = userWalletId
        self.accountId = accountId
        self.tokenItem = tokenItem
        self.coordinator = coordinator
    }

    func onCloseTap() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openCloreMigrationPortal() {
        guard let claimPortalURL else { return }
        coordinator?.openURLInSystemBrowser(url: claimPortalURL)
    }

    func copySignature() {
        UIPasteboard.general.string = signature
    }

    func sign() {
        let messageToSign = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageToSign.isEmpty else {
            signature = ""
            return
        }

        signature = ""

        Task { [weak self] in
            guard let self else { return }

            do {
                guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == self.userWalletId }) else {
                    throw CloreMigrationSigningError.userWalletNotFound
                }

                let signer: CloreMigrationMessageSigner
                if FeatureProvider.isAvailable(.accounts) {
                    guard let accountId else {
                        throw CloreMigrationSigningError.accountNotFound
                    }
                    signer = try CloreMigrationMessageSigner(
                        message: messageToSign,
                        blockchainId: tokenItem.blockchain.networkId,
                        signer: CommonWalletConnectSigner(signer: userWalletModel.signer),
                        wcAccountsWalletModelProvider: userWalletModel.wcAccountsWalletModelProvider,
                        accountId: accountId
                    )
                } else {
                    signer = try CloreMigrationMessageSigner(
                        message: messageToSign,
                        blockchainId: tokenItem.blockchain.networkId,
                        signer: CommonWalletConnectSigner(signer: userWalletModel.signer),
                        walletModelProvider: userWalletModel.wcWalletModelProvider
                    )
                }

                let signature = try await signer.handle()

                await MainActor.run {
                    self.signature = signature
                }
            } catch {
                AppLogger.error(Localization.warningCloreMigrationErrorWalletManagerNotFound, error: error)
            }
        }
    }
}

extension CloreMigrationViewModel: FloatingSheetContentViewModel {}

enum CloreMigrationSigningError: LocalizedError {
    case userWalletNotFound
    case accountNotFound
    case failedToGetWalletModel(blockchainId: String)
    case invalidSignature
}
