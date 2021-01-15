//
//  SecurityManagementViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SecurityManagementViewModel: ViewModel {
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    var bag = Set<AnyCancellable>()
    
    @Published var cardViewModel: CardViewModel! {
        didSet {
            selectedOption = cardViewModel.currentSecOption
            cardViewModel.objectWillChange
                          .receive(on: RunLoop.main)
                          .sink { [weak self] in
                              self?.objectWillChange.send()
                      }
                      .store(in: &bag)
        }
    }
    
    @Published var error: AlertBinder?
    @Published var selectedOption: SecurityManagementOption = .longTap
    @Published var isLoading: Bool = false
    
    var actionButtonPressedHandler: (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void {
        return { completion in
            self.cardViewModel.changeSecOption(self.selectedOption,
                                                 completion: completion) }
    }
    
    func onTap() {
        switch selectedOption {
        case .accessCode, .passCode:
            navigation.securityToWarning = true
        case .longTap:
            isLoading = true
            cardViewModel.changeSecOption(.longTap) { result in
                self.isLoading = false
                switch result {
                case .success:
                    break
                case .failure(let error):
                    if case .userCancelled = error.toTangemSdkError() {
                        return
                    }
                    self.error = error.alertBinder
                }
            }
        }
    }
}


enum SecurityManagementOption: CaseIterable, Identifiable {
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
