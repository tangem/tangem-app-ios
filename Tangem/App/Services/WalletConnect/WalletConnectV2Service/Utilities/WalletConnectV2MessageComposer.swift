//
//  WalletConnectV2MessageComposer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import WalletConnectSwiftV2

protocol WalletConnectV2MessageComposable {
    func makeMessage(for proposal: Session.Proposal, targetBlockchains: [String]) -> String
    func makeMessage(for transaction: Transaction, walletModel: WalletModel, dApp: WalletConnectSavedSession.DAppInfo) -> String
    func makeErrorMessage(with error: WalletConnectV2Error) -> String
}

struct WalletConnectV2MessageComposer: WalletConnectV2MessageComposable {
    func makeMessage(for proposal: Session.Proposal, targetBlockchains: [String]) -> String {
        let proposer = proposal.proposer
        let namespaces = proposal.requiredNamespaces

        let proposerName = proposer.name
        let chains = targetBlockchains.joined(separator: ", ")
        let allMethods = namespaces.map { $0.value.methods.joined(separator: ", ") }.joined(separator: ";\n")
        let allChains = namespaces.map { $0.value.chains.map { $0.absoluteString }.joined(separator: ", ") }.joined(separator: ";\n")
        let allEvents = namespaces.map { $0.value.events.joined(separator: ", ") }.joined(separator: ";\n")
        let proposerDescription = proposer.description
        let proposerURL = proposer.url

        var message = Localization.walletConnectRequestSessionStart(proposerName, chains, proposerURL)
        message += "\n\n\(proposerDescription)"
        AppLog.shared.debug("[WC 2.0] Attempting to establish WalletConnect session for \(proposerName): \nChains: \(allChains)\nMethods: \(allMethods)\nEvents: \(allEvents). Proposer description: \(proposerDescription), url: \(proposerURL)")

        return message
    }

    func makeMessage(for transaction: Transaction, walletModel: WalletModel, dApp: WalletConnectSavedSession.DAppInfo) -> String {
        let totalAmount = transaction.amount + transaction.fee.amount
        let balance = walletModel.wallet.amounts[.coin] ?? .zeroCoin(for: walletModel.wallet.blockchain)
        let message: String = {
            var m = ""
            m += Localization.walletConnectCreateTxMessage(
                dApp.name,
                dApp.url,
                transaction.amount.description,
                transaction.fee.description,
                totalAmount.description,
                walletModel.getBalance(for: .coin)
            )
            if balance < totalAmount {
                m += "\n\n" + Localization.walletConnectCreateTxNotEnoughFunds
            }
            return m
        }()
        return message
    }

    func makeErrorMessage(with error: WalletConnectV2Error) -> String {
        switch error {
        case .unsupportedBlockchains(let blockchainNames):
            var message = Localization.walletConnectErrorUnsupportedBlockchains
            message += blockchainNames.joined(separator: ", ")

            return message
        case .missingBlockchains(let blockchainNames):
            var message = Localization.walletConnectErrorMissingBlockchains
            message += blockchainNames.joined(separator: ", ")

            return message
        case .wrongCardSelected:
            return Localization.walletConnectErrorWrongCardSelected
        case .unknown(let errorMessage):
            return Localization.walletConnectErrorWithFrameworkMessage(errorMessage)
        case .sessionConnetionTimeout:
            return Localization.walletConnectErrorTimeout
        default:
            return Localization.walletConnectGenericErrorWithCode(error.code)
        }
    }
}
