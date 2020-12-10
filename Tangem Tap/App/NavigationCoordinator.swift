//
//  NavigationCoordinator.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class NavigationCoordinator: ObservableObject {
    // MARK: ReadView
    @Published var openMain: Bool = false
    @Published var openShop: Bool = false
    @Published var openDisclaimer: Bool = false
    
    // MARK: DisclaimerView
    @Published var openMainFromDisclaimer: Bool = false
    
    // MARK: SecurityManagementView
    @Published var openWarning: Bool = false
    
    // MARK: MainView
    @Published var showSettings = false
    @Published var showSend = false
    @Published var showSendChoise = false
    @Published var showCreatePayID = false
    @Published var showTopup = false
    @Published var showQRAddress = false
    
    // MARK: SendView
    @Published var showQR = false
}
