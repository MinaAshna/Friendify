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
        NavigationStack {
            VStack(alignment: .center) {
                
                List {
                    Section("How it works") {
                        Label("Start by entering your name",
                              systemImage: "person")
                        Label("We will notify everyone around you, who are using the same app",
                              systemImage: "person.wave.2")
                        Label("We will connect you to the first person who accepts the connection",
                              systemImage: "person.2.wave.2")
                        Label("You can also chat with your new friend",
                              systemImage: "message.badge")
                    }
                    
                    Section("Just for your information") {
                        Label("You don't need internet connection", systemImage: "wifi.slash")
                        Label("CONNECTIVITY",
                              systemImage: "dot.radiowaves.left.and.right")
                        Label("We are not saving your messages",
                              systemImage: "icloud.slash")
                    }
                }
                .listStyle(.plain)
                .font(.body)
                .tint(.primary)
                
                Spacer()
                
                TextField("Please enter your name", text: $viewModel.myObject.displayName)
                    .padding(0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(viewModel.myObject.displayName.isEmpty ? Color.primary.opacity(0.5) : Color.primary,
                                    lineWidth: 0.5)
                            .frame(height: 60)
                    )
                    .frame(width: UIScreen.main.bounds.size.width * 0.9,
                           height: 80)
                    .multilineTextAlignment(.center)
                
                
                NavigationLink {
                    HomeView(viewModel: viewModel, presenter: HomePresenter(viewModel: viewModel))
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                } label: {
                    Text("Let's Go")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: UIScreen.main.bounds.size.width * 0.9,
                               height: 60)
                        .background(viewModel.myObject.displayName.isEmpty ? Color.primary.opacity(0.5) : Color.primary)
                        .cornerRadius(8)
                }
                .disabled(viewModel.myObject.displayName.isEmpty)
                
            }
            .padding([.top,.bottom], 12)
            .navigationTitle("Friendify")
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView(viewModel: AppViewModel())
                .preferredColorScheme(.dark)
        }
        
        NavigationStack {
            OnboardingView(viewModel: AppViewModel())
                .preferredColorScheme(.light)
        }
    }
}
