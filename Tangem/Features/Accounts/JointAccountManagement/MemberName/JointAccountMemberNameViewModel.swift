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

final class JointAccountMemberNameViewModel: ObservableObject {
    @Published var alert: AlertBinder?

    @Published var name: String = "" {
        didSet { validateName() }
    }

    var nameMaxLength: Int { JointAccountMemberNameValidator.maxLength }

    /// The screen starts with an empty field, which is not a name the account can be created with either
    @Published private var validationError: JointAccountMemberNameValidator.ValidationError? = .empty

    /// An empty field is what the screen starts with, the disabled button is the only reaction it deserves
    var hasNameError: Bool {
        validationError != nil && validationError != .empty
    }

    var createButtonIcon: ImageType? {
        creationContext.tangemIconProvider.getMainButtonIcon()?.imageType
    }

    var createButtonDisabled: Bool {
        validationError != nil
    }

    private let nameValidator = JointAccountMemberNameValidator()
    private let creationContext: JointAccountCreationContext
    private weak var coordinator: JointAccountMemberNameRoutable?

    init(
        creationContext: JointAccountCreationContext,
        coordinator: JointAccountMemberNameRoutable?
    ) {
        self.creationContext = creationContext
        self.coordinator = coordinator
    }

    func onCreateTap() {
        creationContext.update(creatorName: name)
        coordinator?.createJointAccount()
    }

    func onCloseTap() {
        guard creationContext.hasUnsavedChanges else {
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
    /// Checked on every keystroke, so the field reports an unsupported character right away.
    func validateName() {
        do throws(JointAccountMemberNameValidator.ValidationError) {
            try nameValidator.validate(name)
            validationError = nil
        } catch {
            validationError = error
        }
    }
}
