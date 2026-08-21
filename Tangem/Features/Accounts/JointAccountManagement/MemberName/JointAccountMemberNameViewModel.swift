//
//  JointAccountMemberNameViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder
import TangemAssets
import TangemFoundation

final class JointAccountMemberNameViewModel: ObservableObject {
    @Published var alert: AlertBinder?
    @Published var name: String = "" {
        didSet { validate(name: name.trimmed()) }
    }

    var nameMaxLength: Int { JointAccountMemberNameValidator.maxLength }

    /// The screen starts empty, which deserves a disabled button and nothing else
    var hasNameError: Bool {
        validationError != nil && validationError != .empty
    }

    var createButtonIcon: ImageType? {
        creationHelper.tangemIconProvider.getMainButtonIcon()?.imageType
    }

    var createButtonDisabled: Bool {
        validationError != nil
    }

    @Published private var validationError: JointAccountMemberNameValidator.ValidationError? = .empty
    @Published private(set) var isCreating = false

    private let nameValidator = JointAccountMemberNameValidator()
    private let creationHelper: JointAccountCreationHelper
    private weak var coordinator: JointAccountMemberNameRoutable?

    init(
        creationHelper: JointAccountCreationHelper,
        coordinator: JointAccountMemberNameRoutable?
    ) {
        self.creationHelper = creationHelper
        self.coordinator = coordinator
    }

    @MainActor
    func onCreateTap() {
        // Raised here rather than inside the task: the task reaches the main actor a hop later, by which time a second
        // tap would already have passed this check
        guard !isCreating else {
            return
        }

        isCreating = true
        creationHelper.update(creatorName: name.trimmed())

        runTask(in: self) { viewModel in
            await viewModel.createAccount()
        }
    }

    func onCloseTap() {
        guard creationHelper.hasUnsavedChanges else {
            coordinator?.closeMemberName()
            return
        }

        alert = JointAccountExitAlert.make { [weak self] in
            self?.coordinator?.closeMemberName()
        }
    }
}

// MARK: - Private

private extension JointAccountMemberNameViewModel {
    @MainActor
    func createAccount() async {
        defer { isCreating = false }

        do {
            try await creationHelper.createAccount()
            coordinator?.openInviteMembers(creationHelper: creationHelper)
        } catch .unknownError(let error) where error.isCancellationError {
            // The user backed out; the flow stays where it is, with nothing to report
        } catch {
            alert = AccountEditErrorAlertBuilder.makeAlert(for: error)
        }
    }

    /// Checked on every keystroke, so the field reports an unsupported character right away.
    func validate(name: String) {
        do throws(JointAccountMemberNameValidator.ValidationError) {
            try nameValidator.validate(name)
            validationError = nil
        } catch {
            validationError = error
        }
    }
}
