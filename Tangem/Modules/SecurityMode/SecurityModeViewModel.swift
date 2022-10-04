//
//  SecurityModeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SecurityModeViewModel: ObservableObject {
    // MARK: ViewState

    @Published var currentSecurityOption: SecurityModeOption
    @Published var availableSecurityOptions: [SecurityModeOption]
    @Published var error: AlertBinder?
    @Published var isLoading: Bool = false

    var isActionButtonEnabled: Bool {
        currentSecurityOption != cardModel.currentSecurityOption
    }

    // MARK: Private

    private let cardModel: CardViewModel
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: SecurityModeRoutable

    init(cardModel: CardViewModel, coordinator: SecurityModeRoutable) {
        self.cardModel = cardModel
        self.coordinator = coordinator

        currentSecurityOption = cardModel.currentSecurityOption
        availableSecurityOptions = cardModel.availableSecurityOptions

        bind()
    }

    func bind() {
        cardModel.$currentSecurityOption
            .sink { [weak self] option in
                self?.currentSecurityOption = option
            }
            .store(in: &bag)
    }

    func actionButtonDidTap() {
        Analytics.log(.securityModeChanged, params: [.mode: currentSecurityOption.rawValue])
        switch currentSecurityOption {
        case .accessCode, .passCode:
            openPinChange()
        case .longTap:
            isLoading = true
            cardModel.changeSecurityOption(.longTap) { [weak self] result in
                self?.isLoading = false

                switch result {
                case .success:
                    break
                case .failure(let error):
                    if case .userCancelled = error.toTangemSdkError() {
                        return
                    }
                    self?.error = error.alertBinder
                }
            }
        }
    }

    func isSelected(option: SecurityModeOption) -> Binding<Bool> {
        Binding<Bool> { [weak self] in
            self?.currentSecurityOption == option
        } set: { [weak self] isSelected in
            guard let self = self else { return }

            if isSelected {
                self.currentSecurityOption = option
            } else {
                self.currentSecurityOption = self.cardModel.currentSecurityOption
            }
        }
    }
}

enum SecurityModeOption: String, CaseIterable, Identifiable, Equatable {
    case longTap
    case passCode
    case accessCode

    var id: String { "\(self)" }

    var title: String {
        switch self {
        case .accessCode:
            return "details_manage_security_access_code".localized
        case .longTap:
            return "details_manage_security_long_tap".localized
        case .passCode:
            return "details_manage_security_passcode".localized
        }
    }

    var titleForDetails: String {
        switch self {
        case .accessCode:
            return "details_manage_security_access_code".localized
        case .longTap:
            return "details_manage_security_long_tap_shorter".localized
        case .passCode:
            return "details_manage_security_passcode".localized
        }
    }

    var subtitle: String {
        switch self {
        case .accessCode:
            return "details_manage_security_access_code_description".localized
        case .longTap:
            return "details_manage_security_long_tap_description".localized
        case .passCode:
            return "details_manage_security_passcode_description".localized
        }
    }
}

// MARK: - Navigation
extension SecurityModeViewModel {
    func openPinChange() {
        coordinator.openPinChange(with: currentSecurityOption.title) { [weak self] completion in
            guard let self = self else { return }

            self.cardModel.changeSecurityOption(self.currentSecurityOption, completion: completion)
        }
    }
}
