//
//  CommonCollectiblesDevnetActions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemCollectibles
import TangemFoundation

// [REDACTED_TODO_COMMENT]
// wallet model instead of reaching into the account model, so nothing outside this folder carries the two
// actions. The real offboarding is a different shape: it withdraws and closes the token accounts before
// the vault.
final class CommonCollectiblesDevnetActions {
    private let accountModel: any CollectiblesAccountModel
    private let coldOwnerProvider: any CollectiblesColdOwnerProvider
    private let coldKeyInteractorFactory: CollectiblesColdKeyInteractorFactory
    private let serviceProvider = CommonCollectiblesChainServiceProvider()
    private let sessionKeyStore: any CollectiblesSessionKeyWalletStore = CommonCollectiblesSessionKeyWalletStore()

    private var userWalletId: UserWalletId { accountModel.id.userWalletId }

    init(accountModel: any CollectiblesAccountModel, userWalletModel: any UserWalletModel) {
        self.accountModel = accountModel
        coldOwnerProvider = CommonCollectiblesColdOwnerProvider(
            keysRepository: userWalletModel.keysRepository,
            derivationStyle: userWalletModel.config.derivationStyle
        )
        coldKeyInteractorFactory = CommonCollectiblesColdKeyInteractorFactory(interactorProvider: userWalletModel)
    }
}

// MARK: - CollectiblesDevnetActions protocol conformance

extension CommonCollectiblesDevnetActions: CollectiblesDevnetActions {
    func topUpAddress() async throws -> String {
        let coldOwner = try coldOwnerKey().blockchainKey

        let usdcMint = try await CommonCollectiblesChainReader(serviceProvider: serviceProvider).configInfo().usdcMint
        let address = try program().vaultUsdcAddress(coldOwner: coldOwner, usdcMint: usdcMint)

        return address
    }

    func feePayerAddress() throws -> String {
        try coldOwnerKey().blockchainKey.base58EncodedString
    }

    func purchaseFeePayerAddress() throws -> String {
        guard case .ready(let vault) = accountModel.state else {
            throw DevnetActionError.vaultNotReady
        }

        return vault.sessionKey.base58EncodedString
    }

    /// Closes the vault alone, which is all a tester needs to run the onboarding twice. The USDC account is
    /// left behind: reclaiming its rent takes `close_token_account`, and that one needs a live vault, so it
    /// only becomes callable again after a vault is deployed for the same owner.
    ///
    /// The session key is dropped only once the chain stops answering with the vault. Dropping it earlier
    /// turns a read that still sees the vault into `rekeyRequired` — a state that says the account exists and
    /// re-arms the local mark this close is meant to clear.
    func closeVault() async throws -> CollectiblesVaultCloseOutcome {
        let coldKey = try coldOwnerKey()
        let instruction = try program().closeVaultInstruction(coldOwner: coldKey.blockchainKey)

        _ = try await broadcast(coldKey: coldKey, instruction: instruction)

        guard await waitForClose() else {
            return .submitted
        }

        do {
            try sessionKeyStore.deleteKey(for: userWalletId)
        } catch {
            CollectiblesLogger.error("Devnet: the session key outlived the vault it signed for", error: error)
        }

        return .confirmed
    }
}

// MARK: - Private implementation

private extension CommonCollectiblesDevnetActions {
    func program() throws -> CollectiblesVaultProgram {
        try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
    }

    func coldOwnerKey() throws -> Wallet.PublicKey {
        guard let coldKey = coldOwnerProvider.coldOwnerKey() else {
            throw DevnetActionError.coldKeyNotDerived
        }

        return coldKey
    }

    func broadcast(coldKey: Wallet.PublicKey, instruction: CollectiblesInstruction) async throws -> String? {
        let rawInstruction = SolanaRawInstruction(
            programId: instruction.programId,
            accounts: instruction.accounts.map { .init(address: $0.address, isSigner: $0.isSigner, isWritable: $0.isWritable) },
            data: instruction.data
        )

        do {
            return try await serviceProvider.service().sendSelfPaid(
                instructions: [rawInstruction],
                feePayer: coldKey.blockchainKey
            ) { message in
                try await coldKeyInteractorFactory.makeInteractor().sign(message: message, coldKey: coldKey)
            }
        } catch let sendError as SolanaSendError {
            switch sendError {
            case .alreadyProcessed:
                return nil
            case .programError(let code, let logs):
                CollectiblesLogger.debug("Devnet: the program rejected the close, code \(code)\n\(logs.joined(separator: "\n"))")
                throw CollectiblesProgramRejection(rawValue: code) ?? sendError
            }
        }
    }

    /// Reads are finalized, so the vault stays readable for a few more slots after the close lands.
    func waitForClose() async -> Bool {
        for _ in 1 ... Constants.closeAttempts {
            do {
                try await Task.sleep(for: Constants.closeInterval)
            } catch {
                return false
            }

            await accountModel.refreshState()
            let state = accountModel.state

            if state == .notOnboarded {
                return true
            }
        }

        return false
    }

    enum DevnetActionError: Error {
        case coldKeyNotDerived
        case vaultNotReady
    }

    enum Constants {
        static let closeAttempts = 10
        static let closeInterval: Duration = .seconds(2)
    }
}
