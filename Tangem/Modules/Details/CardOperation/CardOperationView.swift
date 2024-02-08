//
//  CardOperationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

// [REDACTED_TODO_COMMENT]
// [REDACTED_INFO]
struct CardOperationView: View {
    @ObservedObject var viewModel: CardOperationViewModel

    var body: some View {
        VStack(spacing: 24.0) {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 120.0, weight: .regular, design: .default))
                .foregroundColor(.tangemWarning)
            Text(Localization.commonWarning.uppercased())
                .font(.system(size: 40.0, weight: .medium, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(.tangemWarning)
                .padding(.horizontal, 16.0)
            Text(viewModel.alert)
                .font(.system(size: 29.0, weight: .regular, design: .default))
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .foregroundColor(.tangemGrayDark6)
                .padding(.horizontal, 36.0)
            Spacer()
            MainButton(
                title: viewModel.buttonTitle,
                isLoading: viewModel.isLoading,
                action: viewModel.onTap
            )
            .alert(item: $viewModel.error) { $0.alert }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 16.0)
        }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(viewModel.title)
    }
}

struct CardOperationVIew_Previews: PreviewProvider {
    static var previews: some View {
        CardOperationView(viewModel: .init(
            title: "Manage",
            alert: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Et quis vitae dictumst consequat.",
            actionButtonPressed: { _ in },
            coordinator: SecurityModeCoordinator()
        ))
    }
}
