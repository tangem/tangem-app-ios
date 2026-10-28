//
//  CollectiblesAccountModelsRegistry+AccountListWriter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesAccountModelsRegistry {
    struct AccountListWriter {
        let cryptoAccountsRepository: any CryptoAccountsRepository

        func add(_ config: CryptoAccountPersistentConfig) async {
            do {
                let remoteState = try await cryptoAccountsRepository.getRemoteState()
                let hasMainAccount = remoteState.accounts.contains { account in
                    AccountModelUtils.isMainAccount(account.derivationIdentity)
                }

                guard hasMainAccount else {
                    AccountsLogger.warning("The main account is missing, the collectibles account is not added")
                    return
                }

                _ = try await cryptoAccountsRepository.addNewCryptoAccount(withConfig: config, remoteState: remoteState)
            } catch {
                AccountsLogger.error("Failed to add the collectibles account", error: error)
            }
        }
    }
}
