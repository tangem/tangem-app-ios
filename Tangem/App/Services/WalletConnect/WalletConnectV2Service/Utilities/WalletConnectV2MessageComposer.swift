//
//  WalletConnectV2MessageComposer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import WalletConnectSwiftV2

protocol WalletConnectV2MessageComposable {
    func makeMessage(for proposal: Session.Proposal) -> String
    func makeErrorMessage(_ error: WalletConnectV2Error) -> String
}

struct WalletConnectV2MessageComposer { }

extension WalletConnectV2MessageComposer: WalletConnectV2MessageComposable {
    // [REDACTED_TODO_COMMENT]
    func makeMessage(for proposal: Session.Proposal) -> String {

        let proposer = proposal.proposer
        let namespaces = proposal.requiredNamespaces
        let firstNamespace = namespaces.first?.value
        let notFoundText = "Not found"

        let proposerName = proposer.name
        let chains = "Chains: \(firstNamespace?.chains.map { $0.absoluteString }.joined(separator: ", ") ?? notFoundText)"
        let proposerMethods = "Methods: \(firstNamespace?.methods.joined(separator: ", ") ?? notFoundText)"
        let events = "Events: \(firstNamespace?.events.joined(separator: ", ") ?? notFoundText)"
        let proposerDescription = proposer.description
        let proposerURL = proposer.url

        var message = Localization.walletConnectRequestSessionStart(proposerName, "\(chains)\n\n\(proposerMethods)\n\n\(events)", proposerURL)
        message += "\n\n\(proposerDescription)"

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
        case .unknown(let errorMessage):
            return "We've encountered unknown error. Error code: \(errorMessage). If the problem persists — feel free to contact our support"
        }
    }
}
