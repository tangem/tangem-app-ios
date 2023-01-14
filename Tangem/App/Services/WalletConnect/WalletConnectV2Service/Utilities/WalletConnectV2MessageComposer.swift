//
//  WalletConnectV2MessageComposer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import WalletConnectSwiftV2

protocol WalletConnectV2MessageComposable {
    func makeMessage(for proposal: Session.Proposal, targetBlockchains: [String]) -> String
    func makeErrorMessage(_ error: WalletConnectV2Error) -> String
}

struct WalletConnectV2MessageComposer { }

extension WalletConnectV2MessageComposer: WalletConnectV2MessageComposable {
    // [REDACTED_TODO_COMMENT]
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

    func makeErrorMessage(_ error: WalletConnectV2Error) -> String {
        switch error {
        case .unsupportedBlockchains(let blockchainNames):
            let unsupportedChains = blockchainNames.joined(separator: ", ")

            var message = "Session request contains unsupported blockchains for WalletConnect connection. Unsupported blockchains:\n"
            message += unsupportedChains

            return message
        case .sessionForTopicNotFound:
            return "We've encountered unknown error. Error code: \(error.code). If the problem persists — feel free to contact our support"
        case .missingBlockchains(let blockchainNames):
            var message = "Not all tokens were added to your list. Please add them first and try again. Missing tokens:\n"
            message += blockchainNames.joined(separator: ", ")

            return message

        case .unknown(let errorMessage):
            return "We've encountered unknown error. Error code: \(errorMessage). If the problem persists — feel free to contact our support"
        }
    }
}
