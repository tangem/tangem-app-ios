//
//  SignHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift

protocol SignHandler: AnyObject {
    var server: Server {get}
    func assertAddress(_ address: String) -> Bool
    func askToSign(request: Request, message: String, dataToSign: Data)
}
