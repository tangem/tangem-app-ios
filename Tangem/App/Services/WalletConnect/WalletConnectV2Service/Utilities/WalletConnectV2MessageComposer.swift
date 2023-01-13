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
        case .unsupportedBlockchains(let blockchains):
            let unsupportedChains = blockchains.map { $0.displayName }.joined(separator: ", ")

            var message = "Session request contains unsupported blockchains for WalletConnect connection. List of unsupported blockchains:\n"
            message += unsupportedChains

            return message
        }
    }
}


// Proposal(id: "e8edbaad5873c12b94ad552df984476bb0292434718a921d7a6695b338b6585f",
//         proposer: WalletConnectSwiftV2.AppMetadata(name: "React App",
//                                                    description: "React App for WalletConnect",
//                                                    url: "https://react-app.walletconnect.com",
//                                                    icons: ["https://avatars.githubusercontent.com/u/37784886"],
//                                                    redirect: nil),
//         requiredNamespaces: ["eip155": WalletConnectSwiftV2.ProposalNamespace(chains: Set([eip155:80001, eip155:5, eip155:420]),
//                                                                               methods: Set(["eth_signTypedData", "eth_sendTransaction", "eth_signTransaction", "personal_sign", "eth_sign"]),
//                                                                               events: Set(["chainChanged", "accountsChanged"]),
//                                                                               extensions: nil)],
//         proposal: WalletConnectSwiftV2.SessionProposal(
//            relays: [WalletConnectSwiftV2.RelayProtocolOptions(protocol: "irn", data: nil)],
//            proposer: WalletConnectSwiftV2.Participant(
//                publicKey: "e8edbaad5873c12b94ad552df984476bb0292434718a921d7a6695b338b6585f",
//                metadata: WalletConnectSwiftV2.AppMetadata(
//                    name: "React App",
//                    description: "React App for WalletConnect",
//                    url: "https://react-app.walletconnect.com",
//                    icons: ["https://avatars.githubusercontent.com/u/37784886"],
//                    redirect: nil)),
//            requiredNamespaces: ["eip155": WalletConnectSwiftV2.ProposalNamespace(
//                chains: Set([eip155:80001, eip155:5, eip155:420]),
//
//                methods: Set(["eth_signTypedData", "eth_sendTransaction", "eth_signTransaction", "personal_sign", "eth_sign"]),
//                events: Set(["chainChanged", "accountsChanged"]),
//                extensions: nil)
//            ]
//         )
// )
