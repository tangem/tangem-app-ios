//
//  AccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemPay

protocol AccountModelsManager: AccountModelsReordering, DisposableEntity {
    /// Indicates whether the user can add more additional (not `Main`) crypto accounts to the wallet.
    var canAddCryptoAccounts: Bool { get }

    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> { get }

    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> { get }

    var accountModels: [AccountModel] { get }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { get }

    /// Archived + active
    var totalCryptoAccountsCountPublisher: AnyPublisher<Int, Never> { get }

    /// - Note: Counted apart from the wallet's own accounts, since the two take their derivation indices from
    /// counters of their own.
    var totalJointAccountsCountPublisher: AnyPublisher<Int, Never> { get }

    /// - Note: This method is also responsible for moving custom tokens into the newly created account if they have a matching derivation.
    func addCryptoAccount(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountCreationResult

    func addJointAccount(context: JointAccountCreationContextType) async throws(AccountEditError) -> AccountCreationResult

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo]

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult

    func acceptTangemPayOffer(authorizingInteractor: TangemPayAuthorizing) async throws(TangemPayAuthorizationError)
}
