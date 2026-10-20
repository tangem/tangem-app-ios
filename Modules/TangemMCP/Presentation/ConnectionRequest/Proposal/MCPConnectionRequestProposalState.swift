//
//  MCPConnectionRequestProposalState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import struct TangemFoundation.UserWalletId
import enum TangemUI.ThumbnailWalletViewType

// [REDACTED_TODO_COMMENT]
struct MCPConnectionRequestProposalState: Equatable {
    let navigationTitle = "New connection"

    var agentSummary: AgentSummary
    let agentPermissions = AgentPermissions()
    var userWalletSelector: UserWalletSelector
    var pushPermissionsBanner: PushNotificationsPermissionBanner?

    var declineButton: Button
    var connectButton: Button

    static func initialLoading(userWalletSelector: UserWalletSelector) -> MCPConnectionRequestProposalState {
        MCPConnectionRequestProposalState(
            agentSummary: AgentSummary.loading,
            userWalletSelector: userWalletSelector,
            declineButton: Button.decline,
            connectButton: Button.connect
        )
    }
}

extension MCPConnectionRequestProposalState {
    enum AgentSummary: Equatable {
        case loading
        case content(Agent)
    }
}

extension MCPConnectionRequestProposalState.AgentSummary {
    struct Agent: Equatable {
        let iconURL: URL?
        let name: String
        let host: String
    }
}

extension MCPConnectionRequestProposalState {
    struct AgentPermissions: Equatable {
        let grantedSection = Section(
            header: "This agent will be able to",
            role: .grant,
            permissions: [
                "View balances and activity",
                "Request approval for transactions",
            ]
        )

        let restrictedSection = Section(
            header: "Will not be able to",
            role: .restrict,
            permissions: ["Sign transactions without your notice"]
        )
    }
}

extension MCPConnectionRequestProposalState.AgentPermissions {
    struct Section: Equatable {
        let header: String
        let role: SectionRole
        let permissions: [String]
    }

    enum SectionRole: Equatable {
        case grant
        case restrict
    }
}

extension MCPConnectionRequestProposalState {
    struct UserWalletSelector: Equatable {
        let label = "Wallet"
        let isSelectionAllowed: Bool
        var isEnabled: Bool
        var selection: MCPUserWallet
    }
}

extension MCPConnectionRequestProposalState {
    struct PushNotificationsPermissionBanner: Equatable {
        let title = "Allow notifications"
        let description = "You’ll get a notification to approve each transaction. Without notifications, the agent can’t connect."
        let buttonTitle = "Open Settings"
    }
}

extension MCPConnectionRequestProposalState {
    struct Button: Equatable {
        let title: String
        var state: ButtonState

        static let decline = Button(title: "Decline", state: .disabled)
        static let connect = Button(title: "Connect", state: .disabled)
    }

    enum ButtonState: Equatable {
        case loading
        case enabled
        case disabled
    }
}
