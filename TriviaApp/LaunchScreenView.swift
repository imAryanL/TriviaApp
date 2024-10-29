import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color(red: 0.651, green: 0.600, blue: 0.533)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Trivia Game")
                    .font(.custom("ChalkboardSE-Bold", size: 45))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Image("LaunchImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .padding(.vertical, 20)
                
                VStack(spacing: 10) {
                    Text("Aryan Lakhani")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Z-Number: Z23724811")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
} 