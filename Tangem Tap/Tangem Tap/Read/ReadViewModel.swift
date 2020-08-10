//
//  ReadViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class ReadViewModel: ObservableObject {
    enum State {
        case welcome
        case ready
        case read
    }
    
    @Published var state: State = .welcome
    
    func openShop() {
        UIApplication.shared.open(URL(string: "https://shop.tangem.com/?afmc=1i&utm_campaign=1i&utm_source=leaddyno&utm_medium=affiliate")!, options: [:], completionHandler: nil)
    }
    
    func nextState() {
        switch state {
        case .read:
            break
        case .ready:
            state = .read
        case .welcome:
            state = .ready
        }
    }
}
