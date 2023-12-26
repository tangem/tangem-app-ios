//
//  SendRoutableMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendRoutableMock: SendRoutable {
    init() {}

    func explore(url: URL) {}
    func share(url: URL) {}
    func dismiss() {}
    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {}
}
