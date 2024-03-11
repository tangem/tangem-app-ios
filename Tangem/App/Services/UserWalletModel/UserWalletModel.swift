//
//  UserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import TangemSdk

protocol UserWalletModel: MainHeaderSupplementInfoProvider, TotalBalanceProviding, MultiWalletMainHeaderSubtitleDataSource, AnalyticsContextDataProvider, MainHeaderUserWalletStateInfoProvider, EmailDataProvider, WalletConnectUserWalletInfoProvider, AnyObject {
    var tokensCount: Int? { get }
    var analyticsContextData: AnalyticsContextData { get }
    var hasBackupCards: Bool { get }
    var config: UserWalletConfig { get }
    var userWalletId: UserWalletId { get }
    var userWallet: StoredUserWallet { get }
    var tangemApiAuthData: TangemApiTarget.AuthData { get }
    var walletModelsManager: WalletModelsManager { get }
    var userTokensManager: UserTokensManager { get }
    var userTokenListManager: UserTokenListManager { get }
    var signer: TangemSigner { get }
    var updatePublisher: AnyPublisher<Void, Never> { get }
    var emailData: [EmailCollectedData] { get }
    var backupInput: OnboardingInput? { get } // [REDACTED_TODO_COMMENT]
    var twinInput: OnboardingInput? { get }
    var cardImagePublisher: AnyPublisher<CardImageResult, Never> { get }
    func updateWalletName(_ name: String)
    func validate() -> Bool
    func onBackupCreated(_ card: Card)
}
