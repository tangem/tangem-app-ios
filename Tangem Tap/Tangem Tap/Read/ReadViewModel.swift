//
//  ReadViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

class ReadViewModel: ObservableObject {
    enum State {
        case welcome
        case ready
        case read
    }
    
    var sdkService: TangemSdkService
    @Published var openDetails: Bool = false
    @Published var state: State = .welcome
    
    init(sdkService: TangemSdkService) {
        self.sdkService = sdkService
    }
    
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
    
    func scan() {
        sdkService.scan { [weak self] scanResult in
            switch scanResult {
            case .success:
                self?.openDetails = true
            case .failure(let error):
                //[REDACTED_TODO_COMMENT]
                break
            }
        }
    }
}
