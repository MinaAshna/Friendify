//
//  OnboardingView.swift
//  Friendify
//
//  Created by Mina Ashna on 16/04/2022.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Copenhagen Cocoa :)")
                    .font(.title)
                    .lineLimit(2)
                    .padding()
                    .multilineTextAlignment(.center)

                Spacer()

                Text("Please enter your name")
                TextField("", text: $viewModel.displayName)
                    .frame(height: 60)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.primary, lineWidth: 0.5)
                    )
                    .padding()
                    .multilineTextAlignment(.center)

                Spacer()

                NavigationLink {
                    ContentView(viewModel: viewModel)
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                } label: {
                    Text("Let's Go")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 80, height: 45)
                        .padding()
                        .background(Color.primary)
                        .cornerRadius(8)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(viewModel: ViewModel())
            .preferredColorScheme(.dark)

        OnboardingView(viewModel: ViewModel())
            .preferredColorScheme(.light)
    }
}
