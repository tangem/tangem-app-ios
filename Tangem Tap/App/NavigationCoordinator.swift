//
//  NavigationCoordinator.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct NavigationCoordinator {
    // MARK: ReadView
    var openMain: Bool = false
    var openDisclaimer: Bool = false
    
    // MARK: DisclaimerView
    var openMainFromDisclaimer: Bool = false
    
    // MARK: SecurityManagementView
    var openWarning: Bool = false
    
    // MARK: MainView
    var showSettings = false
    var showSend = false
    var showSendChoise = false
    var showCreatePayID = false
    
    // MARK: SendView
    var showQR = false
}
