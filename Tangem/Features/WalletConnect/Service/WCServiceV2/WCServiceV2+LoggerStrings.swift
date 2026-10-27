//
//  WCServiceV2+LoggerStrings.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

extension WCServiceV2 {
    enum LoggerStrings {
        static let userRejectWC = "User reject WC connection"
        static let failedToRejectWC = "Failed to reject WC connection"

        static func failedToDisconnectSession(_ topic: String) -> String {
            "Failed to disconnect session with topic: \(topic)"
        }

        static func sessionEstablished(_ session: Session) -> String {
            "Session established: \(session)"
        }

        static func sessionWasFound(_ topic: String) -> String {
            "Session with topic (\(topic)) was found. Deleting session from storage..."
        }

        static func receiveDeleteMessageSessionNotFound(_ topic: String, _ reason: Reason) -> String {
            "Receive Delete session message with topic: \(topic). Delete reason: \(reason). But session not found."
        }

        static func receiveDeleteMessage(_ topic: String, _ reason: Reason) -> String {
            "Receive Delete session message with topic: \(topic). Delete reason: \(reason)."
        }

        /// Session proposals
        static func sessionProposal(_ sessionProposal: Session.Proposal, _ context: VerifyContext?) -> String {
            "Session proposal: \(sessionProposal) with verify context: \(String(describing: context))"
        }

        static func namespacesToApprove(_ namespaces: [String: SessionNamespace]) -> String {
            "Namespaces to approve for session connection: \(namespaces)"
        }

        /// Connection handling
        static func tryingToPairClient(_ url: WalletConnectURI) -> String {
            "Trying to pair client: \(url)"
        }

        static func establishedPair(_ url: WalletConnectURI) -> String {
            "Established pair for \(url)"
        }

        static func failedToConnect(_ url: WalletConnectURI) -> String {
            "Failed to connect to \(url)"
        }

        /// Disconnect actions
        static func successDisconnectDelete(_ topic: String) -> String {
            "Success disconnect/delete topic \(topic)"
        }

        static func failedDisconnectDelete(_ topic: String) -> String {
            "Failed to disconnect/delete topic \(topic)"
        }
    }
}
