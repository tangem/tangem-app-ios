//
//  StringifyMacro.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntax

public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: MacroError.requiresArgument(macro: "#stringify")
                )
            )
            return "\"\""
        }

        return "\(literal: argument.description)"
    }
}
