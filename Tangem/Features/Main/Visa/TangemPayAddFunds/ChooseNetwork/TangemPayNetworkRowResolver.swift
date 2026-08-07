//
//  TangemPayNetworkRowResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemPay

enum TangemPayNetworkRowResolver {
    static func resolve(_ networks: [TangemPayBalance.Network]) -> [TangemPayNetworkRow] {
        networks.compactMap { network in
            guard let blockchain = blockchain(name: network.name, isTestnet: network.isTestnet) else {
                return nil
            }

            return TangemPayNetworkRow(
                id: network.chainId,
                title: blockchain.displayName,
                subtitle: network.tokens.map(\.token).joined(separator: ", "),
                icon: NetworkImageProvider().provide(by: blockchain, filled: true),
                status: network.status,
                action: action(for: network, blockchain: blockchain)
            )
        }
    }

    static func receiveInput(
        for network: TangemPayBalance.Network,
        depositAddress: String
    ) -> TangemPayReceiveSheetViewModel.Input? {
        blockchain(name: network.name, isTestnet: network.isTestnet).map { blockchain in
            receiveInput(for: network, blockchain: blockchain, depositAddress: depositAddress)
        }
    }

    private static func action(
        for network: TangemPayBalance.Network,
        blockchain: Blockchain
    ) -> TangemPayNetworkRow.Action? {
        let receiveAction = network.depositAddress.map { depositAddress in
            TangemPayNetworkRow.Action.receive(
                receiveInput(for: network, blockchain: blockchain, depositAddress: depositAddress)
            )
        }

        switch network.status {
        case .disabled:
            return .explainOtherNetworks
        case .enabled:
            return receiveAction
        case .notIssued:
            return receiveAction ?? .issueContract(chainId: network.chainId)
        case .undefined:
            return nil
        }
    }

    private static func receiveInput(
        for network: TangemPayBalance.Network,
        blockchain: Blockchain,
        depositAddress: String
    ) -> TangemPayReceiveSheetViewModel.Input {
        TangemPayReceiveSheetViewModel.Input(
            blockchain: blockchain,
            networkTitle: blockchain.displayName,
            depositAddress: depositAddress,
            tokens: network.tokens.map {
                .init(symbol: $0.token, contractAddress: $0.tokenContractAddress)
            }
        )
    }

    private static func blockchain(name: String, isTestnet: Bool) -> Blockchain? {
        switch name {
        case Blockchain.ethereum(testnet: false).networkId: .ethereum(testnet: isTestnet)
        case Blockchain.polygon(testnet: false).networkId: .polygon(testnet: isTestnet)
        case Blockchain.bsc(testnet: false).networkId: .bsc(testnet: isTestnet)
        case Blockchain.base(testnet: false).networkId: .base(testnet: isTestnet)
        case Blockchain.arbitrum(testnet: false).networkId: .arbitrum(testnet: isTestnet)
        case Blockchain.tron(testnet: false).networkId: .tron(testnet: isTestnet)
        default: nil
        }
    }
}
