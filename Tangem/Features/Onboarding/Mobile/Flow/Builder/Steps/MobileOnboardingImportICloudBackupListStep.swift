//
//  MobileOnboardingImportICloudBackupListStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemMobileWalletBackup

final class MobileOnboardingImportICloudBackupListStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingImportICloudBackupListViewModel

    init(
        backups: [MobileWalletBackup],
        delegate: MobileOnboardingImportICloudBackupListDelegate
    ) {
        viewModel = MobileOnboardingImportICloudBackupListViewModel(
            backups: backups,
            delegate: delegate
        )
    }

    override func makeView() -> any View {
        MobileOnboardingImportICloudBackupListView(viewModel: viewModel)
    }
}
