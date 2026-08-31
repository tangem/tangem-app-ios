//
//  MobileBackupStorageUnavailableViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupStorageUnavailableViewModel: ObservableObject {
    var title: String {
        let serviceName = MobileBackupConstants.iCloudServiceName
        switch input.mode {
        case .info:
            return Localization.hwCloudBackupPermissionsTitleV2(serviceName)
        case .retry:
            return Localization.hwCloudBackupAccessUnavailableTitle(serviceName)
        }
    }

    var description: String {
        let serviceName = MobileBackupConstants.appleICloudServiceName
        switch input.mode {
        case .info:
            return Localization.hwCloudBackupPermissionsDescriptionV2(serviceName)
        case .retry:
            return Localization.hwCloudBackupAccessUnavailableDescription(serviceName)
        }
    }

    var actionTitle: String {
        switch input.mode {
        case .info: Localization.commonGotIt
        case .retry: Localization.hwCloudBackupRetry
        }
    }

    private let input: MobileBackupStorageUnavailableInput
    private weak var output: MobileBackupStorageUnavailableOutput?
    private weak var coordinator: MobileBackupStorageUnavailableRoutable?

    init(
        input: MobileBackupStorageUnavailableInput,
        output: MobileBackupStorageUnavailableOutput?,
        coordinator: MobileBackupStorageUnavailableRoutable
    ) {
        self.input = input
        self.output = output
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension MobileBackupStorageUnavailableViewModel {
    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.coordinator?.closeMobileBackupStorageUnavailable()
        }
    }

    func onActionTap() {
        switch input.mode {
        case .info:
            runTask(in: self) { viewModel in
                await viewModel.coordinator?.closeMobileBackupStorageUnavailable()
            }
        case .retry:
            runTask(in: self) { viewModel in
                await viewModel.coordinator?.closeMobileBackupStorageUnavailable()
                viewModel.output?.didRequestRetry()
            }
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupStorageUnavailableViewModel: FloatingSheetContentViewModel {}
