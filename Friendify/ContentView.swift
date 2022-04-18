//
//  ContentView.swift
//  Friendify
//
//  Created by Mina Ashna on 16/04/2022.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack {
                Button {
                   
                } label: {
                    Text("Let's Mingle :)")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(height: 45)
                        .padding()
                        .background(Color.primary)
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)

        ContentView()
            .preferredColorScheme(.light)
    }
}
