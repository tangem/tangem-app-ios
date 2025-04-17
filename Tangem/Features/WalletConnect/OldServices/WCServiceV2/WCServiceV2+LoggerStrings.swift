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
        // General errors
        static let walletConnectRedirectFailure = "WalletConnect redirect configure failure"
        static let userRejectWC = "User reject WC connection"
        static let failedToRejectWC = "Failed to reject WC connection"
        static let failedToApproveSession = "Failed to approve Session"
        static let noSelectedWallet = "Info provider is not setup. Saved session will miss some info"

        /// Session handling
        static func failedToFindSession(_ id: Int) -> String {
            "Failed to find session with id: \(id). Attempt to disconnect session failed"
        }

        static func attemptToDisconnect(_ topic: String) -> String {
            "Attempt to disconnect session with topic: \(topic)"
        }

        static func sessionDisconnected(_ topic: String) -> String {
            "Session with topic: \(topic) was disconnected from SignAPI. Removing from storage"
        }

        static func failedToRemoveSession(_ topic: String) -> String {
            "Failed to remove session with \(topic) from SignAPI. Removing anyway from storage"
        }

        static func failedToDisconnectSession(_ topic: String) -> String {
            "Failed to disconnect session with topic: \(topic)"
        }

        static func failedDisconnectSessions(_ userWalletId: String) -> String {
            "Failed to disconnect session while disconnecting all sessions for user wallet with id: \(userWalletId)"
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

        static func attemptingToApproveSession(_ proposal: Session.Proposal) -> String {
            "Attempting to approve session proposal: \(proposal)"
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

        static func savedSession(_ topic: String, _ url: String) -> String {
            "Saving session with topic: \(topic).\ndApp url: \(url)"
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
