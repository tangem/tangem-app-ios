//
//  AssociatedValueInsensitiveEquatableMarco.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftSyntaxMacros
import SwiftSyntax
import SwiftDiagnostics

public struct AssociatedValueInsensitiveEquatableMarco: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure the macro is applied only to enums
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: MacroError.doesNotApplyToEnum
            )
            context.diagnose(diagnostic)
            return []
        }

        let enumName = enumDecl.name.text

        // Build switch cases that compare (lhs, rhs) ignoring associated values
        let casePatternsWithWildcardsArrays: [[String]] = enumDecl.memberBlock.members.map { member -> [String] in
            guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return [] }

            return enumCaseDecl.elements.map { element -> String in
                let caseName = element.name.text
                if let assoc = element.parameterClause {
                    let count = assoc.parameters.count
                    if count == 0 {
                        return "case (.\(caseName), .\(caseName)): return true"
                    } else {
                        let wildcards = Array(repeating: "_", count: count).joined(separator: ", ")
                        return "case (.\(caseName)(\(wildcards)), .\(caseName)(\(wildcards))): return true"
                    }
                } else {
                    return "case (.\(caseName), .\(caseName)): return true"
                }
            }
        }

        let casePatternsWithWildcards: [String] = casePatternsWithWildcardsArrays.flatMap { $0 }

        // Build the body of the ~= function
        let switchBody: String
        if casePatternsWithWildcards.isEmpty {
            switchBody = "return false"
        } else {
            switchBody = """
            switch (lhs, rhs) {
            \(casePatternsWithWildcards.joined(separator: "\n  "))
            default: return false
            }
            """
        }

        let code = """
        static func == (lhs: \(enumName), rhs: \(enumName)) -> Bool {
          \(switchBody)
        }
        """

        return [DeclSyntax(stringLiteral: code)]
    }

    enum MacroError: DiagnosticMessage {
        case doesNotApplyToEnum

        var message: String {
            switch self {
            case .doesNotApplyToEnum:
                return "`@AssociatedValueInsensitiveEquatable` can only be applied to enum declarations"
            }
        }

        var diagnosticID: MessageID {
            MessageID(domain: "AssociatedValueInsensitiveEquatableMarco", id: "Error")
        }

        var severity: DiagnosticSeverity { .error }
    }
}
