//
//  WarningListView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct WarningsContainer {
    var criticals: [TapWarning]
    var warnings: [TapWarning]
    var infos: [TapWarning]
    
    static let empty = WarningsContainer(criticals: [], warnings: [], infos: [])
    
    mutating func add(_ warning: TapWarning) {
        switch warning.priority {
        case .critical: criticals.append(warning)
        case .warning: criticals.append(warning)
        case .info: criticals.append(warning)
        }
    }
    
    mutating func add(_ warnings: [TapWarning]) {
        warnings.forEach { add($0) }
    }
}

struct WarningListView: View {
    
    @Binding var warnings: WarningsContainer
    var warningButtonAction: (Int, WarningPriority) -> Void
    
    private let transition = AnyTransition.scale.combined(with: .opacity)
    
    var body: some View {
        ForEach(Array(warnings.criticals.enumerated()), id: \.element) { (i, item) in
            WarningView(warning: warnings.criticals[i]) {
                self.buttonAction(at: i, priority: .critical)
            }
            .transition(transition)
        }
        ForEach(Array(warnings.warnings.enumerated()), id: \.element) { (i, item) in
            WarningView(warning: warnings.warnings[i]) {
                self.buttonAction(at: i, priority: .warning)
            }
            .transition(transition)
        }
        ForEach(Array(warnings.infos.enumerated()), id: \.element) { (i, item) in
            WarningView(warning: warnings.infos[i]) {
                self.buttonAction(at: i, priority: .info)
            }
            .transition(transition)
        }
    }
    
    private func buttonAction(at index: Int, priority: WarningPriority) {
        withAnimation {
            self.warningButtonAction(index, priority)
        }
    }
}
