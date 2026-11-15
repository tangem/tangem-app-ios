//
//  MCPConnectionRequestProposalState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import struct TangemFoundation.UserWalletId
import enum TangemLocalization.Localization
import enum TangemUI.ThumbnailWalletViewType

struct MCPConnectionRequestProposalState: Equatable {
    let navigationTitle = Localization.wcNewConnection

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
        case content(MCPAgent)
    }
}

extension MCPConnectionRequestProposalState {
    struct AgentPermissions: Equatable {
        let grantedSection = Section(
            header: Localization.mcpConnectionRequestAgentCan,
            role: .grant,
            permissions: [
                Localization.mcpConnectionRequestCanViewBalance,
                Localization.wcConnectionReqeustRequestApproval,
            ]
        )

        let restrictedSection = Section(
            header: Localization.wcConnectionReqeustWillNot,
            role: .restrict,
            permissions: [Localization.wcConnectionReqeustCantSign]
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
        let label = Localization.commonWallet
        let isSelectionAllowed: Bool
        var isEnabled: Bool
        var selection: MCPUserWallet
    }
}

extension MCPConnectionRequestProposalState {
    struct PushNotificationsPermissionBanner: Equatable {
        let title = Localization.pushNotificationSettingsBannerTitle
        let description = Localization.mcpConnectionRequestNotificationsDescription
        let buttonTitle = Localization.commonOpenSettingsButtonTitle
    }
}

extension MCPConnectionRequestProposalState {
    struct Button: Equatable {
        let title: String
        var state: ButtonState

        static let decline = Button(title: Localization.commonDecline, state: .disabled)
        static let connect = Button(title: Localization.wcCommonConnect, state: .disabled)
    }

    enum ButtonState: Equatable {
        case loading
        case enabled
        case disabled
    }
}
