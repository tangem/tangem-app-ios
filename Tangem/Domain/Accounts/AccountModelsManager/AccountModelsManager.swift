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

    /// Joins an account someone else created, taking up the slot the invite was issued for.
    func joinJointAccount(context: JointAccountJoinContext) async throws(AccountEditError) -> AccountCreationResult

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo]

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult

    func reloadAccountsFromRemote() async

    func acceptTangemPayOffer(authorizingInteractor: TangemPayAuthorizing) async throws(TangemPayAuthorizationError)

    func authorizeTangemPayOfferForResidency(
        authorizingInteractor: TangemPayAuthorizing
    ) async throws(TangemPayAuthorizationError) -> (any TangemPayResidencyInteractor)?

    /// Same as `acceptTangemPayOffer`, but the campaign's card issue order is placed before KYC so that the
    /// tariff plan selection screen never appears.
    func acceptTangemPayCampaignOffer(
        authorizingInteractor: TangemPayAuthorizing,
        campaignKey: String
    ) async throws(TangemPayCampaignOfferError)
}

enum TangemPayCampaignOfferError: Error {
    case authorization(TangemPayAuthorizationError)
    case order(TangemPayCampaignOrderError)
    /// Authorization revealed a Payment account the local state had hidden. Recoverable: resolve again.
    case accountAlreadyExists
    case unexpectedState
}
