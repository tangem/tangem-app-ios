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
import TangemPay

protocol UserWalletModel:
    MainHeaderSupplementInfoProvider,
    TotalBalanceProvider,
    MultiWalletMainHeaderSubtitleDataSource,
    AnalyticsContextDataProvider,
    MainHeaderUserWalletStateInfoProvider,
    EmailDataProvider,
    WCUserWalletInfoProvider,
    KeysDerivingProvider,
    TangemPayAuthorizingProvider,
    WalletSelectorInfoProvider,
    UserWalletModelUnlockerResolvable,
    UserWalletInfoProvider,
    DisposableEntity,
    AnyObject {
    var name: String { get }
    var hasBackupCards: Bool { get }
    var config: UserWalletConfig { get }
    var userWalletId: UserWalletId { get }
    var tangemApiAuthData: TangemApiAuthorizationData? { get }
    var keysRepository: KeysRepository { get }
    var refcodeProvider: RefcodeProvider? { get }
    var signer: TangemSigner { get }
    var updatePublisher: AnyPublisher<UpdateResult, Never> { get }
    var backupInput: OnboardingInput? { get } // [REDACTED_TODO_COMMENT]
    var nftManager: NFTManager { get }
    var walletImageProvider: WalletImageProviding { get }
    var accountModelsManager: AccountModelsManager { get }
    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager { get }
    var addressBookManager: AddressBookManager { get }

    func validate() -> Bool
    func update(type: UpdateRequest)
    func addAssociatedCard(cardId: String)
}

enum UpdateRequest {
    case backupCompleted(card: Card, associatedCardIds: Set<String>)
    case updateSensitiveInfo(sensitiveInfo: StoredUserWallet.SensitiveInfo)
    case newName(_ name: String)
    case mnemonicBackupCompleted
    case iCloudBackupCompleted
    case accessCodeDidSet
    case accessCodeDidSkip
}

enum UpdateResult {
    case configurationChanged(model: UserWalletModel)
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
