//
//  SendRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol SendRoutable: AnyObject {
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func closeModule()
    func openQRScanner(with codeBinding: Binding<String>)
}
