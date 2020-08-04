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
    func openShop() {
        UIApplication.shared.open(URL(string: "https://shop.tangem.com/?afmc=1i&utm_campaign=1i&utm_source=leaddyno&utm_medium=affiliate")!, options: [:], completionHandler: nil)
    }
}
