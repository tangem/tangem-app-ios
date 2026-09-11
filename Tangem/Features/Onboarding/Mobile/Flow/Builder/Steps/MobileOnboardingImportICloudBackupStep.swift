//
//  MobileOnboardingImportICloudBackupStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemMobileWalletBackup

final class MobileOnboardingImportICloudBackupStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingImportICloudBackupViewModel

    init(
        dataSource: MobileOnboardingImportICloudBackupDataSource,
        delegate: MobileOnboardingImportICloudBackupDelegate
    ) {
        viewModel = MobileOnboardingImportICloudBackupViewModel(
            dataSource: dataSource,
            delegate: delegate
        )
    }

    override func makeView() -> any View {
        MobileOnboardingImportICloudBackupView(viewModel: viewModel)
    }
}
