//
//  TangemProblemDetailError+JSON.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemNetworkUtils

extension TangemProblemDetailError {
    var jsonString: String {
        var fields = [#""status":\#(httpStatusCode)"#]

        if let message {
            fields.append(#""detail":"\#(message)""#)
        }

        if let code {
            fields.append(#""code":"\#(code)""#)
        }

        return "{\(fields.joined(separator: ","))}"
    }
}
