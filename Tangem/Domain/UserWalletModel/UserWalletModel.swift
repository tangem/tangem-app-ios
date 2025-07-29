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
import TangemNFT
import TangemFoundation

protocol UserWalletModel:
    MainHeaderSupplementInfoProvider,
    TotalBalanceProviding,
    MultiWalletMainHeaderSubtitleDataSource,
    AnalyticsContextDataProvider,
    MainHeaderUserWalletStateInfoProvider,
    EmailDataProvider,
    OldWalletConnectUserWalletInfoProvider,
    KeysDerivingProvider,
    AnyObject {
    var hasBackupCards: Bool { get }
    var config: UserWalletConfig { get }
    var userWalletId: UserWalletId { get }
    var tangemApiAuthData: TangemApiTarget.AuthData { get }
    var walletModelsManager: WalletModelsManager { get }
    var userTokensManager: UserTokensManager { get }
    var userTokenListManager: UserTokenListManager { get }
    var nftManager: NFTManager { get }
    var keysRepository: KeysRepository { get }
    var refcodeProvider: RefcodeProvider? { get }
    var signer: TangemSigner { get }
    var updatePublisher: AnyPublisher<Void, Never> { get }
    var backupInput: OnboardingInput? { get } // [REDACTED_TODO_COMMENT]
    var walletImageProvider: WalletImageProviding { get }
    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager { get }
    var name: String { get }

    func validate() -> Bool
    func onBackupUpdate(type: BackupUpdateType)
    func updateWalletName(_ name: String)
    func addAssociatedCard(cardId: String)
    func cleanup()
}

enum BackupUpdateType {
    case primaryCardBackuped(card: Card)
    case backupCompleted
}
