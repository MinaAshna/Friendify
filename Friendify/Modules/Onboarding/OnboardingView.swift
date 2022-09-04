//
//  OnboardingView.swift
//  Friendify
//
//  Created by Mina Ashna on 16/04/2022.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        GeometryReader { reader in
            NavigationView {
                VStack(alignment: .center) {
                    Text("Welcome to iOSDevUK")
                        .font(.title)
                        .lineLimit(2)
                        .padding()
                        .multilineTextAlignment(.center)

                    Spacer()

                    Image("ven")
                        .resizable()
                        .scaledToFit()

                    TextField("Please enter your name", text: $viewModel.myObject.displayName)
                        .padding(0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(viewModel.myObject.displayName.isEmpty ? Color.primary.opacity(0.5) : Color.primary,
                                        lineWidth: 0.5)
                                .frame(height: 60)
                        )
                        .frame(width: reader.size.width * 0.9, height: 80)
                        .multilineTextAlignment(.center)

                    Spacer()

                    NavigationLink {
                        HomeView(viewModel: viewModel, presenter: HomePresenter(viewModel: viewModel))
                            .navigationBarBackButtonHidden(true)
                            .navigationBarHidden(true)
                    } label: {
                        Text("Let's Go")
                            .font(.title3)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(width: reader.size.width * 0.9, height: 60)
                            .background(viewModel.myObject.displayName.isEmpty ? Color.primary.opacity(0.5) : Color.primary)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.myObject.displayName.isEmpty)

                }
                .padding([.top,.bottom], 8)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(viewModel: AppViewModel())
            .preferredColorScheme(.dark)

        OnboardingView(viewModel: AppViewModel())
            .preferredColorScheme(.light)
    }
}
