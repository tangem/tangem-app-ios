//
//  ReferralView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReferralView: View {
    @ObservedObject var viewModel: ReferralViewModel

    var isLoading: Bool { !viewModel.isLoading }

    var body: some View {
        ScrollView {
            VStack {
                Assets.referralDude
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 40)
                    .frame(maxHeight: 222)
                Text("referral_title".localized)
                    .font(Fonts.Bold.title1)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 57)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                content
                Spacer()
            }
        }
        .navigationBarTitle("details_referral".localized)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    var content: some View {
        if viewModel.isLoading {
            loaderContent
        } else {
            referralContent
        }
    }

    @ViewBuilder
    var referralContent: some View {
        // [REDACTED_TODO_COMMENT]
        Color.green
    }

    @ViewBuilder
    var loaderContent: some View {
        VStack(alignment: .leading, spacing: 38) {
            ReferralLoaderView { Assets.cryptocurrencies }
            ReferralLoaderView { Assets.discount }
        }
        .padding(.horizontal, 16)
    }
}



struct ReferralView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReferralView(viewModel: ReferralViewModel(coordinator: ReferralCoordinator()))
        }
    }
}
