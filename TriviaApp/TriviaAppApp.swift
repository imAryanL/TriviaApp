//
//  TriviaAppApp.swift
//  TriviaApp
//
//  Created by aryan on 10/26/24.
//

import SwiftUI

@main
struct TriviaAppApp: App {
    @State private var isActive = false
    
    var body: some Scene {
        WindowGroup {
            if !isActive {
                LaunchScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
            } else {
                ContentView()
            }
        }
    }
}
