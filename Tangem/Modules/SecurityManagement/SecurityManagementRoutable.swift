//
//  SecurityManagementRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol SecurityManagementRoutable: AnyObject {
    func openPinChange(with title: String, action: @escaping (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void)
}
