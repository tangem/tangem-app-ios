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
            guard let blockchain = TangemPayUtilities.blockchain(for: network) else {
                return nil
            }

            return TangemPayNetworkRow(
                id: network.chainId,
                title: blockchain.displayName,
                subtitle: subtitle(for: network),
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
        TangemPayUtilities.blockchain(for: network).map { blockchain in
            receiveInput(for: network, blockchain: blockchain, depositAddress: depositAddress)
        }
    }

    private static func subtitle(for network: TangemPayBalance.Network) -> String {
        let symbols = switch network.status {
        case .notIssued:
            Constants.notIssuedTokenSymbols
        case .enabled, .disabled, .undefined:
            network.tokens.map(\.token)
        }

        return symbols.joined(separator: ", ")
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

    private enum Constants {
        static let notIssuedTokenSymbols = ["USDT", "USDC"]
    }
}
