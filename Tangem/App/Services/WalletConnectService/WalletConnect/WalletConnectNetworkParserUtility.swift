//
//  WalletConnectNetworkParserUtility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import BlockchainSdk

enum WalletConnectNetworkParserUtility {
    static func parse(dAppInfo: Session.DAppInfo, isTestnet: Bool) -> Blockchain? {
        if dAppInfo.peerMeta.url.absoluteString.contains("pancakeswap.finance") {
            return Blockchain.bsc(testnet: isTestnet)
        } else if let id = dAppInfo.chainId {
            if let blockchain = makeBlockchain(from: id) {
                return blockchain
            }

            return nil

            // There is no adequate way to determine which network we are trying to connect to and create a WC session,
            // icon links are the only thing that is different and allows us to determine whether we are connecting to testnet or mainnet.
            // But this only applies to binance.org and suddenly for wallet.matic.network.
            // So far, I could not find alternative services where you can connect Binance wallet via WC.
            // peer_id is never the same for the dApp
            // I think this list will continue to expand
        } else if dAppInfo.peerMeta.url.absoluteString.contains("polygon.technology") {
            return Blockchain.polygon(testnet: isTestnet)
        } else if dAppInfo.peerMeta.url.absoluteString.hasSuffix("binance.org") {
            if dAppInfo.peerMeta.icons.first?.absoluteString.contains("dex-bin") ?? false {
                return Blockchain.binance(testnet: false)
            } else if !dAppInfo.peerMeta.icons.filter({ $0.absoluteString.contains("testnet-bin") }).isEmpty {
                return Blockchain.binance(testnet: true)
            } else {
                return nil
            }
        } else if dAppInfo.peerMeta.url.absoluteString.contains("honeyswap.1hive.eth.limo") {
            // This service doesn't return chainID despite the fact they support both Gnosis and Polygon.
            // [REDACTED_TODO_COMMENT]
            // https://github.com/1Hive/honeyswap-interface/issues/83
            return Blockchain.gnosis
        } else {
            // WC interface doesn't provide info about network. So in cases when chainId is null we use ethereum network
            // Dapps on ethereum mainnet sending null in chainId
            return Blockchain.ethereum(testnet: isTestnet)
        }
    }

    private static func makeBlockchain(from chainId: Int) -> Blockchain? {
        let allBlockchains = Blockchain.supportedBlockchains.union(Blockchain.supportedTestnetBlockchains)
        return allBlockchains.first(where: { $0.chainId == chainId })
    }
}
