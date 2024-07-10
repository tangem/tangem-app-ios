//
//  SendDestinationRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol SendDestinationRoutable: AnyObject {
    func openQRScanner(with codeBinding: Binding<String>, networkName: String)
}
