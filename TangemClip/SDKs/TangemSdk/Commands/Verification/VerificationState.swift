//
//  VerificationState.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


public enum VerificationState: String, Codable {
    case passed
    case offline
    case failed
    case notVerified
    case cancelled
}
