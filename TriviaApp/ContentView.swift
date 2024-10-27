//
//  ContentView.swift
//  TriviaApp
//
//  Created by aryan on 10/26/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var triviaManager = TriviaManager()
    @State private var selectedCategory = "Any Category"
    @State private var selectedDifficulty = "Medium"
    @State private var selectedType = "Any Type"
    @State private var selectedTimerDuration = "30 seconds"
    @State private var numberOfQuestionsString = ""
    @State private var isCategoryDropdownVisible = false
    @State private var isTypeDropdownVisible = false
    @State private var isTimerDurationDropdownVisible = false
    @State private var difficulty: Double = 0.5
    @State private var isShowingQuestions = false
    
    let skyBlue = Color(red: 0.4, green: 0.6, blue: 0.9)
    let darkerGray = Color(red: 0.15, green: 0.15, blue: 0.15)
    let sectionGray = Color(red: 0.25, green: 0.25, blue: 0.25)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                VStack(spacing: 0) {
                    skyBlue
                        .frame(height: UIScreen.main.bounds.height * 0.15)
                        .overlay(
                            Text("Trivia Game")
                                .font(.system(size: 45, weight: .bold)) // Increased from 40 to 45
                                .foregroundColor(.white)
                                .padding(.top, 60),
                            alignment: .center // Added alignment parameter
                        )
                    darkerGray
                    skyBlue
                        .frame(height: UIScreen.main.bounds.height * 0.15)
                        .overlay(
                            NavigationLink(destination: QuestionView(
                                numberOfQuestions: numberOfQuestionsString,
                                category: selectedCategory,
                                difficulty: difficultyText,
                                type: selectedType,
                                timerDuration: selectedTimerDuration
                            ).navigationBarHidden(true), isActive: $isShowingQuestions) {
                                Text("Start Game")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 80) // Increased from 50 to 80 for a narrower button
                        )
                }
                .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 20) {
                    VStack(spacing: 25) {
                        // Number of questions input
                        TextField("", text: $numberOfQuestionsString)
                            .textFieldStyle(DefaultTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: numberOfQuestionsString) { newValue in
                                // Only allow numeric characters
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    numberOfQuestionsString = filtered
                                }
                            }
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color(.darkGray))
                            .cornerRadius(8)
                            .overlay(
                                HStack {
                                    Text("Number of Questions")
                                        .foregroundColor(Color(.systemGray4)) // Lighter gray for better visibility
                                        .opacity(numberOfQuestionsString.isEmpty ? 1 : 0)
                                    Spacer()
                                }
                                .padding(.leading, 10)
                            )
                        
                        // Category selection
                        Button(action: { isCategoryDropdownVisible.toggle() }) {
                            HStack {
                                Text("Select Category")
                                    .foregroundColor(Color(.systemGray4)) // Lighter color
                                Spacer()
                                HStack {
                                    Text(selectedCategory)
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(Color(.systemGray4)) // Lighter color
                            }
                        }
                        
                        // Difficulty section
                        HStack {
                            Text("Difficulty: \(difficultyText)")
                                .foregroundColor(Color(.systemGray4)) // Lighter color
                            Spacer()
                            Slider(value: $difficulty, in: 0...1, step: 0.5)
                                .accentColor(.blue)
                                .frame(width: 150)
                        }
                        
                        // Type selection
                        Button(action: { isTypeDropdownVisible.toggle() }) {
                            HStack {
                                Text("Select Type")
                                    .foregroundColor(Color(.systemGray4)) // Lighter color
                                Spacer()
                                HStack {
                                    Text(selectedType)
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(Color(.systemGray4)) // Lighter color
                            }
                        }
                        
                        // Timer duration selection
                        Button(action: { isTimerDurationDropdownVisible.toggle() }) {
                            HStack {
                                Text("Timer Duration")
                                    .foregroundColor(Color(.systemGray4)) // Lighter color
                                Spacer()
                                HStack {
                                    Text(selectedTimerDuration)
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(Color(.systemGray4)) // Lighter color
                            }
                        }
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    .background(sectionGray)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, -30)
                
                // Overlays
                if isCategoryDropdownVisible {
                    categoryOverlay(content: categorySelectionView)
                }
                if isTypeDropdownVisible {
                    typeOverlay(content: typeSelectionView)
                }
                if isTimerDurationDropdownVisible {
                    timerDurationOverlay(content: timerDurationSelectionView)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    var difficultyText: String {
        switch difficulty {
        case 0: return "Easy"
        case 0.5: return "Medium"
        case 1: return "Hard"
        default: return "Medium"
        }
    }
    
    var numberOfQuestions: Int {
        return max(1, min(50, Int(numberOfQuestionsString) ?? 10))
    }
    
    var categorySelectionView: some View {
        VStack(spacing: 0) {
            Text("Select Category")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
            
            if triviaManager.isCategoriesLoading {
                ProgressView("Loading categories...")
            } else if let error = triviaManager.categoriesError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(triviaManager.categories) { category in
                            Button(action: {
                                selectedCategory = category.name
                                withAnimation {
                                    isCategoryDropdownVisible = false
                                }
                            }) {
                                Text(category.name)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Divider()
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    var typeSelectionView: some View {
        VStack(spacing: 0) {
            Text("Select Type")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(["Any Type", "Multiple Choice", "True or False"], id: \.self) { type in
                        Button(action: {
                            selectedType = type
                            withAnimation {
                                isTypeDropdownVisible = false
                            }
                        }) {
                            Text(type)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                    }
                }
            }
        }
        .background(Color.white)
    }
    
    var timerDurationSelectionView: some View {
        VStack(spacing: 0) {
            Text("Select Timer Duration")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(["30 seconds", "60 seconds", "120 seconds", "300 seconds", "1 hour"], id: \.self) { duration in
                        Button(action: {
                            selectedTimerDuration = duration
                            withAnimation {
                                isTimerDurationDropdownVisible = false
                            }
                        }) {
                            Text(duration)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                    }
                }
            }
        }
        .background(Color.white)
    }
    
    func categoryOverlay<Content: View>(content: Content) -> some View {
        GeometryReader { geometry in
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    content
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.6)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10),
                    alignment: .center // Added alignment parameter
                )
                .transition(.move(edge: .bottom))
        }
        .zIndex(100)
    }
    
    func typeOverlay<Content: View>(content: Content) -> some View {
        GeometryReader { geometry in
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    content
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.25)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10),
                    alignment: .center // Added alignment parameter
                )
                .transition(.move(edge: .bottom))
        }
        .zIndex(100)
    }
    
    func timerDurationOverlay<Content: View>(content: Content) -> some View {
        GeometryReader { geometry in
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    content
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.4)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10),
                    alignment: .center // Added alignment parameter
                )
                .transition(.move(edge: .bottom))
        }
        .zIndex(100)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
