//
//  MobileBackupNotFoundViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupNotFoundViewModel: ObservableObject {
    let title = Localization.hwCloudBackupNotFoundTitle
    let description = Localization.hwCloudBackupNotFoundDescription
    let createActionTitle = Localization.hwCloudBackupNotFoundCreate
    let forgetActionTitle = Localization.hwCloudBackupNotFoundForget

    private weak var output: MobileBackupNotFoundOutput?
    private weak var coordinator: MobileBackupNotFoundRoutable?

    init(output: MobileBackupNotFoundOutput, coordinator: MobileBackupNotFoundRoutable) {
        self.output = output
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension MobileBackupNotFoundViewModel {
    func onCreateTap() {
        runTask(in: self) { viewModel in
            await viewModel.coordinator?.closeMobileBackupNotFound()
            viewModel.output?.didRequestCreate()
        }
    }

    func onForgetTap() {
        runTask(in: self) { viewModel in
            await viewModel.coordinator?.closeMobileBackupNotFound()
            viewModel.output?.didRequestForget()
        }
    }

    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.coordinator?.closeMobileBackupNotFound()
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupNotFoundViewModel: FloatingSheetContentViewModel {}
