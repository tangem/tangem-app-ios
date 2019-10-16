//
//  SignTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum SignEvent {
    case success(Data)
    case failure(TaskError)
}
