//
//  SendType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemNFT

typealias NonFungibleTokenParameters = (asset: NFTAsset, collection: NFTCollection)

enum SendType {
    case send(walletModel: any WalletModel, parameters: SendParameters)
    case nft(walletModel: any WalletModel, parameters: NonFungibleTokenParameters)
    case sell(walletModel: any WalletModel, parameters: PredefinedSellParameters)
    case staking(walletModel: any WalletModel, manager: StakingManager)
    case unstaking(walletModel: any WalletModel, manager: StakingManager, action: UnstakingModel.Action)
    case restaking(walletModel: any WalletModel, manager: StakingManager, action: RestakingModel.Action)
    case stakingSingleAction(walletModel: any WalletModel, manager: StakingManager, action: StakingSingleActionModel.Action)
    case onramp(walletModel: any WalletModel)
}

// MARK: - Convenience extensions

//extension SendType {
//    static var send: Self { .send(parameters: .init()) }
//}
