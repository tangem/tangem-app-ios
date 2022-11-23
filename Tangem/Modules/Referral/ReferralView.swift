//
//  ReferralView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import AlertToast

struct ReferralView: View {
    @ObservedObject var viewModel: ReferralViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Assets.referralDude
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, 40)

                    Text("referral_title".localized)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 57)
                        .padding(.top, 28)
                        .padding(.bottom, 32)

                    content
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 10))

                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height + geometry.safeAreaInsets.bottom)

            }
            .edgesIgnoringSafeArea(.bottom)
            .toast(
                isPresenting: $viewModel.showCodeCopiedToast,
                offsetY: geometry.safeAreaInsets.top / 2,
                alert: {
                    AlertToast(
                        displayMode: .hud,
                        type: .regular,
                        title: "referral_promo_code_copied".localized,
                        style: .style(
                            backgroundColor: Colors.Background.action.opacity(0.6),
                            titleColor: Colors.Text.primary2,
                            titleFont: Fonts.Regular.footnote
                        )
                    )
                }
            )
        }
        .alert(item: $viewModel.errorAlert, content: { $0.alert })
        .navigationBarTitle("details_referral_title", displayMode: .inline)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isProgramInfoLoaded {
            referralContent
        } else {
            loaderContent
        }
    }

    @ViewBuilder
    private var referralContent: some View {
        VStack(spacing: 0) {
            ReferralPointView(
                Assets.cryptoCurrencies,
                header: { Text("referral_point_currencies_title") },
                description: {
                    Text("referral_point_currencies_description_prefix".localized + " ") +
                        Text(viewModel.award).foregroundColor(Colors.Text.primary1) +
                        Text(viewModel.awardDescriptionSuffix)
                }
            )

            ReferralPointView(
                Assets.discount,
                header: { Text("referral_point_discount_title") },
                description: {
                    Text("referral_point_discount_description_prefix".localized + " ") +
                        Text(viewModel.discount).foregroundColor(Colors.Text.primary1) +
                        Text(" " + "referral_point_discount_description_suffix".localized)
                })
                .padding(.top, viewModel.isAlreadyReferral ? 20 : 38)

            Spacer()

            if viewModel.isAlreadyReferral {
                alreadyReferralBottomView
            } else {
                notReferralView
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var loaderContent: some View {
        VStack(alignment: .leading, spacing: 38) {
            ReferralPlaceholderPointView(icon: Assets.cryptoCurrencies)

            ReferralPlaceholderPointView(icon: Assets.discount)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var tosButton: some View {
        Button(action: viewModel.openTOS) {
            Text(viewModel.tosButtonPrefix) +
                Text("common_terms_and_conditions").foregroundColor(Colors.Text.accent) +
                Text(" " + "referral_tos_suffix".localized)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .font(Fonts.Regular.footnote)
        .foregroundColor(Colors.Text.tertiary)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var alreadyReferralBottomView: some View {
        VStack(spacing: 14) {
            Spacer()

            HStack {
                Text("referral_friends_bought_title")
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                Text(viewModel.numberOfWalletsBought)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }
            .roundedBackground(with: Colors.Background.primary,
                               padding: 16,
                               radius: 14)
            .padding(.top, 24)

            VStack(spacing: 8) {
                Text("referral_promo_code_title")
                    .style(Fonts.Bold.footnote,
                           color: Colors.Text.tertiary)

                Text(viewModel.promoCode)
                    .style(Fonts.Regular.title1,
                           color: Colors.Text.primary1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Colors.Background.primary)
            .cornerRadius(14)

            HStack(spacing: 12) {
                TangemButton(title: "common_copy",
                             systemImage: "square.on.square",
                             iconPosition: .leading,
                             iconPadding: 10,
                             action: viewModel.copyPromoCode)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                   layout: .flexibleWidth))

                TangemButton(title: "common_share",
                             systemImage: "arrowshape.turn.up.forward",
                             iconPosition: .leading,
                             iconPadding: 10,
                             action: showShareSheet)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                   layout: .flexibleWidth))
            }

            tosButton
        }
    }

    @ViewBuilder
    private var notReferralView: some View {
        VStack(spacing: 12) {
            tosButton

            TangemButton(
                title: "referral_button_participate",
                image: "tangemIcon",
                iconPosition: .trailing,
                iconPadding: 10,
                action: {
                    runTask(viewModel.participateInReferralProgram)
                }
            )
            .buttonStyle(
                TangemButtonStyle(colorStyle: .black,
                                  layout: .flexibleWidth,
                                  isLoading: viewModel.isProcessingRequest)
            )
        }
    }

    private func showShareSheet() {
        let av = UIActivityViewController(activityItems: [viewModel.shareLink], applicationActivities: nil)
        UIApplication.topViewController?.present(av, animated: true, completion: nil)
    }
}

struct ReferralView_Previews: PreviewProvider {
    private static let demoCard = PreviewCard.tangemWalletBackuped
    static var previews: some View {
        NavigationView {
            ReferralView(
                viewModel: ReferralViewModel(cardModel: demoCard.cardModel,
                                             userWalletId: Data(),
                                             coordinator: ReferralCoordinator())
            )
        }
        .previewGroup(devices: [.iPhone8], withZoomed: false)

        NavigationView {
            ReferralView(
                viewModel: ReferralViewModel(cardModel: demoCard.cardModel,
                                             userWalletId: Data(hexString: "6772C99F8B400E6F59FFCE0C4A66193BFD49DE2D9738868DE36F5E16569BB4F9"),
                                             coordinator: ReferralCoordinator()
                )
            )
        }
        .previewGroup(devices: [.iPhone8], withZoomed: false)
    }
}
