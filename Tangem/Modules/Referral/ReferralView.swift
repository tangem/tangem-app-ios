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
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var viewModel: ReferralViewModel

    private let dudePadding: CGFloat = 14

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Assets.referralDude.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(
                            RadialGradient(
                                colors: [
                                    Colors.Control.unchecked,
                                    // DO NOT replace it with Color.clear. Apparently it is not the same on iOS 15
                                    Colors.Control.unchecked.opacity(0),
                                ],
                                center: .bottom,
                                startRadius: (colorScheme == .light ? 0.5 : 0.30) * (geometry.size.width - 2 * dudePadding),
                                endRadius: 0.65 * (geometry.size.width - 2 * dudePadding)
                            )
                            .cornerRadiusContinuous(14)
                        )
                        .padding(.horizontal, dudePadding)

                    Text(Localization.referralTitle)
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
            .toast(isPresenting: $viewModel.showCodeCopiedToast) {
                AlertToast(type: .complete(Colors.Icon.accent), title: Localization.referralPromoCodeCopied)
            }
        }
        .alert(item: $viewModel.errorAlert, content: { $0.alert })
        .navigationBarTitle(Text(Localization.detailsReferralTitle), displayMode: .inline)
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
            IconWithMessageView(
                Assets.cryptoCurrencies,
                header: { Text(Localization.referralPointCurrenciesTitle) },
                description: {
                    Text(viewModel.awardDescription(highlightColor: Colors.Text.primary1))
                }
            )

            IconWithMessageView(
                Assets.discount,
                header: { Text(Localization.referralPointDiscountTitle) },
                description: {
                    Text(Localization.referralPointDiscountDescriptionPrefix + " ") +
                        Text(viewModel.discount).foregroundColor(Colors.Text.primary1) +
                        Text(" " + Localization.referralPointDiscountDescriptionSuffix)
                }
            )
            .padding(.top, viewModel.isAlreadyReferral ? 20 : 38)

            Spacer()

            if viewModel.isAlreadyReferral {
                alreadyReferralBottomView
            } else {
                notReferralView
            }
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private var loaderContent: some View {
        VStack(alignment: .leading, spacing: 38) {
            IconWithMessagePlaceholderView(icon: Assets.cryptoCurrencies)

            IconWithMessagePlaceholderView(icon: Assets.discount)

            Spacer()
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private var tosButton: some View {
        Button(action: viewModel.openTOS) {
            Text(viewModel.tosButtonPrefix) +
                Text(Localization.commonTermsAndConditions).foregroundColor(Colors.Text.accent) +
                Text(" " + Localization.referralTosSuffix)
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

            VStack(spacing: 8) {
                Text(Localization.referralPromoCodeTitle)
                    .style(
                        Fonts.Bold.footnote,
                        color: Colors.Text.tertiary
                    )

                Text(viewModel.promoCode)
                    .style(
                        Fonts.Regular.title1,
                        color: Colors.Text.primary1
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Colors.Background.primary)
            .cornerRadius(14)

            HStack(spacing: 12) {
                TangemButton(
                    title: Localization.commonCopy,
                    systemImage: "square.on.square",
                    iconPosition: .leading,
                    iconPadding: 10,
                    action: viewModel.copyPromoCode
                )
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .black,
                    layout: .flexibleWidth
                ))

                TangemButton(
                    title: Localization.commonShare,
                    systemImage: "arrowshape.turn.up.forward",
                    iconPosition: .leading,
                    iconPadding: 10,
                    action: viewModel.sharePromoCode
                )
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .black,
                    layout: .flexibleWidth
                ))
            }

            VStack(spacing: 0) {
                HStack {
                    Text(Localization.referralFriendsBoughtTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Spacer()

                    Text(viewModel.numberOfWalletsBought)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                }
                .padding(14)

                if viewModel.hasPurchases {
                    Separator(height: 0.5, color: Colors.Stroke.primary)

                    expectedAwards
                }
            }
            .roundedBackground(
                with: Colors.Background.primary,
                padding: 0,
                radius: 14
            )

            tosButton
        }
    }

    @ViewBuilder
    private var expectedAwards: some View {
        VStack(spacing: 0) {
            if viewModel.hasExpectedAwards {
                HStack(spacing: 0) {
                    Text(Localization.referralExpectedAwards)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Spacer()

                    Text(viewModel.numberOfWalletsForPayments)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
                .padding(14)
            } else {
                Text(Localization.referralNoExpectedAwards)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }

            ForEach(viewModel.expectedAwards, id: \.date) { expectedAward in
                HStack {
                    Text(expectedAward.date)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Spacer()

                    Text(expectedAward.amount)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                }
                .padding(14)
            }

            if viewModel.canExpandExpectedAwards {
                Button {
                    withAnimation(nil) {
                        viewModel.expectedAwardsExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.expandButtonText)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                        Image(systemName: viewModel.expectedAwardsExpanded ? "chevron.up" : "chevron.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 9)
                            .foregroundColor(Colors.Text.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
            }
        }
    }

    @ViewBuilder
    private var notReferralView: some View {
        VStack(spacing: 12) {
            tosButton

            MainButton(
                title: Localization.referralButtonParticipate,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                action: {
                    runTask(viewModel.participateInReferralProgram)
                }
            )
        }
    }
}

struct ReferralView_Previews: PreviewProvider {
    private static let demoCard = PreviewCard.tangemWalletBackuped
    static var previews: some View {
        NavigationView {
            ReferralView(
                viewModel: ReferralViewModel(
                    input: .init(
                        userWalletId: Data(),
                        supportedBlockchains: SupportedBlockchains.all,
                        userTokensManager: UserTokensManagerMock()
                    ),
                    coordinator: ReferralCoordinator()
                )
            )
        }
        .previewGroup(devices: [.iPhone7], withZoomed: false)

        NavigationView {
            ReferralView(
                viewModel: ReferralViewModel(
                    input: .init(
                        userWalletId: Data(hexString: "6772C99F8B400E6F59FFCE0C4A66193BFD49DE2D9738868DE36F5E16569BB4F9"),
                        supportedBlockchains: SupportedBlockchains.all,
                        userTokensManager: UserTokensManagerMock()
                    ),
                    coordinator: ReferralCoordinator()
                )
            )
        }
        .previewGroup(devices: [.iPhone7], withZoomed: false)
    }
}
