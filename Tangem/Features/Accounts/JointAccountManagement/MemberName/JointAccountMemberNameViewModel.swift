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
    @Published var name: String {
        didSet {
            validate(name: name.trimmed())
            helper.keepDraft(name: name)
        }
    }

    var submitButtonTitle: String { helper.submitButtonTitle }

    var nameMaxLength: Int { JointAccountMemberNameValidator.maxLength }

    /// The screen starts empty, which deserves a disabled button and nothing else
    var hasNameError: Bool {
        validationError != nil && validationError != .empty
    }

    var submitButtonIcon: ImageType? {
        helper.tangemIconProvider.getMainButtonIcon()?.imageType
    }

    var submitButtonDisabled: Bool {
        validationError != nil
    }

    @Published private var validationError: JointAccountMemberNameValidator.ValidationError? = .empty
    @Published private(set) var isSubmitting = false

    private let nameValidator = JointAccountMemberNameValidator()
    private let helper: any JointAccountMemberNameHelper
    private weak var coordinator: JointAccountMemberNameRoutable?

    init(
        helper: any JointAccountMemberNameHelper,
        coordinator: JointAccountMemberNameRoutable?
    ) {
        self.helper = helper
        self.coordinator = coordinator

        name = helper.initialName
        validate(name: helper.initialName.trimmed())
    }

    @MainActor
    func onSubmitTap() {
        // Raised here rather than inside the task: the task reaches the main actor a hop later, by which time a second
        // tap would already have passed this check
        guard !isSubmitting else {
            return
        }

        isSubmitting = true

        runTask(in: self) { viewModel in
            await viewModel.submit()
        }
    }

    func onCloseTap() {
        guard helper.hasUnsavedChanges else {
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
    func submit() async {
        defer { isSubmitting = false }

        do throws(AccountEditError) {
            try await helper.submit(name: name.trimmed())
        } catch .unknownError(let underlying) where underlying.isCancellationError {
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
