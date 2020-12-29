//
//  WarningListView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct WarningListView: View {
    var warnings: WarningsContainer
    var warningButtonAction: (Int, WarningPriority) -> Void
    var spacing: CGFloat = 10
    
    private let transition = AnyTransition.scale.combined(with: .opacity)
    
    var body: some View {
        VStack(spacing: spacing) {
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
    }
    
    private func buttonAction(at index: Int, priority: WarningPriority) {
        withAnimation {
            self.warningButtonAction(index, priority)
        }
    }
}

struct WarningListView_Previews: PreviewProvider {
    static let container: WarningsContainer = .init(
        criticals: [ TapWarning(title: "Warning", message: "Blockchain is currently unavailable", priority: .critical, type: .permanent)],
        warnings: [TapWarning(title: "Attention!", message: "Something huuuuuge is going to happen!", priority: .warning, type: .permanent)],
        infos: [TapWarning(title: "Good news, everyone!", message: "New Tangem Cards available. Visit our web site to learn more", priority: .info, type: .temporary)]
    )
    
    @ObservedObject static var warnings: WarningsContainer = container
    static var previews: some View {
        ScrollView {
            WarningListView(warnings: warnings, warningButtonAction: { (index, priority) in
                warningButtonAction(at: index, priority: priority)
            })
        }
        
    }
    
    static func warningButtonAction(at index: Int, priority: WarningPriority) {
        let warning: TapWarning
        switch priority {
        case .info:
            warning = warnings.infos[index]
        case .critical:
            warning = warnings.criticals[index]
        case .warning:
            warning = warnings.warnings[index]
        }
        
        container.remove(warning)
    }
}
