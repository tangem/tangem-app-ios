//
//  FloatingSheetRegistry+JointAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

/// The flow is entered from several places and is presented over a full screen cover, so the sheets are registered
/// once on the shared registry instead of from the view hierarchy of a concrete coordinator.
extension FloatingSheetRegistry {
    func registerJointAccountFloatingSheets() {
        register(JointAccountWalletSelectionViewModel.self) {
            JointAccountWalletSelectionView(viewModel: $0)
        }

        register(JointAccountMemberDetailsViewModel.self) {
            JointAccountMemberDetailsView(viewModel: $0)
        }

        register(JointAccountJoinConfirmationViewModel.self) {
            JointAccountJoinConfirmationView(viewModel: $0)
        }

        register(JointAccountActivationConfirmationViewModel.self) {
            JointAccountActivationConfirmationView(viewModel: $0)
        }

        register(JointAccountInviteSafetyViewModel.self) {
            JointAccountInviteSafetyView(viewModel: $0)
        }

        register(JointAccountOperationDetailsViewModel.self) {
            JointAccountOperationDetailsView(viewModel: $0)
        }

        register(JointAccountSignersViewModel.self) {
            JointAccountSignersView(viewModel: $0)
        }
    }
}
