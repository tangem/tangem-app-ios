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
    WalletSelectorInfoProvider,
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
    var updatePublisher: AnyPublisher<UpdateResult, Never> { get }
    var backupInput: OnboardingInput? { get } // [REDACTED_TODO_COMMENT]
    var walletImageProvider: WalletImageProviding { get }
    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager { get }
    var name: String { get }

    func validate() -> Bool
    func update(type: UpdateRequest)
    func addAssociatedCard(cardId: String)
    func cleanup()
}

enum UpdateRequest {
    case backupStarted(card: Card)
    case backupCompleted
    case newName(_ name: String)
}

enum UpdateResult {
    case backupDidChange
    case nameDidChange(name: String)

    var newName: String? {
        switch self {
        case .nameDidChange(let name):
            return name
        default:
            return nil
        }
    }
}
