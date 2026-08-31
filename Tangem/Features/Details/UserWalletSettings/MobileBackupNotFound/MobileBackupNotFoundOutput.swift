//
//  MobileBackupNotFoundOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileBackupNotFoundOutput: AnyObject {
    func didRequestCreate()
    func didRequestForget()
}
