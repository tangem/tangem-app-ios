//
//  UserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

protocol UserWalletModel: MainHeaderInfoProvider, TotalBalanceProviding, MultiWalletMainHeaderSubtitleDataSource, AnyObject {
    var isMultiWallet: Bool { get }
    var tokensCount: Int? { get }
    var config: UserWalletConfig { get }
    var userWalletId: UserWalletId { get }
    var userWallet: UserWallet { get }
    var didPerformInitialTokenSync: Bool { get }
    var emailConfig: EmailConfig? { get }
    var walletModelsManager: WalletModelsManager { get }
    var userTokensManager: UserTokensManager { get }
    var userTokenListManager: UserTokenListManager { get }
    var signer: TangemSigner { get }
    var updatePublisher: AnyPublisher<Void, Never> { get }
    var didPerformInitialTokenSyncPublisher: AnyPublisher<Bool, Never> { get }

    func initialUpdate()
    func updateWalletName(_ name: String)
}
