import SwiftUI

private struct Question: Codable {
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
}

private struct QuestionResponse: Codable {
    let response_code: Int
    let results: [Question]
}

private class QuestionViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var shuffledAnswers: [[String]] = []
    
    func fetchQuestions(amount: Int, category: String, difficulty: String, type: String) {
        isLoading = true
        error = nil
        shuffledAnswers = []
        
        // Convert type to API parameter
        let typeParam = type == "Multiple Choice" ? "multiple" : 
                       type == "True or False" ? "boolean" : ""
        
        // Add this category ID mapping
        let categoryMapping = [
            "General Knowledge": "9",
            "Entertainment: Books": "10",
            "Entertainment: Film": "11",
            "Entertainment: Music": "12",
            "Entertainment: Musicals & Theatres": "13",
            "Entertainment: Television": "14",
            "Entertainment: Video Games": "15",
            "Entertainment: Board Games": "16",
            "Science & Nature": "17",
            "Science: Computers": "18",
            "Science: Mathematics": "19",
            "Mythology": "20",
            "Sports": "21",
            "Geography": "22",
            "History": "23",
            "Politics": "24",
            "Art": "25",
            "Celebrities": "26",
            "Animals": "27",
            "Vehicles": "28",
            "Entertainment: Comics": "29",
            "Science: Gadgets": "30",
            "Entertainment: Japanese Anime & Manga": "31",
            "Entertainment: Cartoon & Animations": "32"
        ]
        
        var urlString = "https://opentdb.com/api.php?amount=\(amount)"
        
        // Add category parameter if not "Any Category"
        if category != "Any Category", let categoryId = categoryMapping[category] {
            urlString += "&category=\(categoryId)"
        }
        
        // Add difficulty if not "Any Difficulty"
        if difficulty != "Any Difficulty" {
            urlString += "&difficulty=\(difficulty.lowercased())"
        }
        
        // Add type if specified
        if !typeParam.isEmpty {
            urlString += "&type=\(typeParam)"
        }
        
        guard let url = URL(string: urlString) else {
            self.error = "Invalid URL"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(QuestionResponse.self, from: data)
                    self?.questions = decodedResponse.results
                    // Shuffle answers once when questions are received
                    self?.shuffledAnswers = decodedResponse.results.map { question in
                        var choices = question.incorrect_answers
                        choices.append(question.correct_answer)
                        return choices.shuffled()
                    }
                } catch {
                    self?.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func getAnswerChoices(for index: Int) -> [String] {
        guard index < shuffledAnswers.count else { return [] }
        return shuffledAnswers[index]
    }
}

struct QuestionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = QuestionViewModel()
    @State private var selectedAnswers: [Int: String] = [:]
    @State private var timeRemaining: Int
    @State private var showingSummary = false  // Add this
    @State private var finalScore = 0          // Add this
    @State private var answeredQuestions: [(question: String, userAnswer: String, correctAnswer: String)] = [] // Add this
    @State private var quizTimedOut = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let numberOfQuestions: String
    let category: String
    let difficulty: String
    let type: String
    let timerDuration: String
    let darkerGray = Color(red: 0.15, green: 0.15, blue: 0.15) // Changed from 0.5 to 0.15 for blue component
    let mauve = Color(red: 0.6, green: 0.4, blue: 0.5) // Matching home screen's mauve
    let beige = Color(red: 0.65, green: 0.60, blue: 0.55) // Regular beige for unselected
    let selectedBeige = Color(red: 0.45, green: 0.40, blue: 0.35) // Darker beige for selected state
    
    
    
    init(numberOfQuestions: String, category: String, difficulty: String, type: String, timerDuration: String) {
        self.numberOfQuestions = numberOfQuestions
        self.category = category
        self.difficulty = difficulty
        self.type = type
        self.timerDuration = timerDuration
        
        let duration = timerDuration.components(separatedBy: " ")[0]
        if timerDuration.contains("hour") {
            _timeRemaining = State(initialValue: 3600)
        } else {
            _timeRemaining = State(initialValue: Int(duration) ?? 30)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Change the background to be less prominent
                Color(red: 0.15, green: 0.15, blue: 0.15) // Darker gray instead of black
                    .ignoresSafeArea()
                
                VStack {
                    // Timer and Back button section
                    HStack {
                        // Back button aligned to the left
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5))
                        }
                        .frame(width: 80, alignment: .leading)
                        
                        // Single line timer
                        Text("Time Remaining: \(timeString(from: timeRemaining))")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                            .frame(width: 80)
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    
                    // Questions ScrollView
                    ScrollView {
                        VStack(spacing: 40) { // Increased from 20 to 40 for more space between questions
                            ForEach(viewModel.questions.indices, id: \.self) { index in
                                // Single box containing everything for the question
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(viewModel.questions[index].category)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("Question \(index + 1) of \(viewModel.questions.count)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(viewModel.questions[index].question
                                        .replacingOccurrences(of: "&quot;", with: "\"")
                                        .replacingOccurrences(of: "&#039;", with: "'")
                                        .replacingOccurrences(of: "&eacute;", with: "é")
                                        .replacingOccurrences(of: "&amp;", with: "&")
                                        .replacingOccurrences(of: "&acute;", with: "´")
                                        .replacingOccurrences(of: "&grave;", with: "`")
                                        .replacingOccurrences(of: "&ldquo;", with: "\"")
                                        .replacingOccurrences(of: "&rdquo;", with: "\"")
                                        .replacingOccurrences(of: "&lsquo;", with: "'")
                                        .replacingOccurrences(of: "&rsquo;", with: "'")
                                        .replacingOccurrences(of: "&ndash;", with: "–")
                                        .replacingOccurrences(of: "&mdash;", with: "—")
                                    )
                                    .font(.title3)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 5)
                                    
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.getAnswerChoices(for: index), id: \.self) { answer in
                                            Button(action: {
                                                selectedAnswers[index] = answer
                                            }) {
                                                HStack {
                                                    Text(answer
                                                        .replacingOccurrences(of: "&quot;", with: "\"")
                                                        .replacingOccurrences(of: "&#039;", with: "'")
                                                        .replacingOccurrences(of: "&eacute;", with: "é")
                                                        .replacingOccurrences(of: "&amp;", with: "&")
                                                        .replacingOccurrences(of: "&acute;", with: "´")
                                                        .replacingOccurrences(of: "&grave;", with: "`")
                                                        .replacingOccurrences(of: "&ldquo;", with: "\"")
                                                        .replacingOccurrences(of: "&rdquo;", with: "\"")
                                                        .replacingOccurrences(of: "&lsquo;", with: "'")
                                                        .replacingOccurrences(of: "&rsquo;", with: "'")
                                                        .replacingOccurrences(of: "&ndash;", with: "–")
                                                        .replacingOccurrences(of: "&mdash;", with: "—")
                                                    )
                                                    .foregroundColor(.white)
                                                    
                                                    Spacer()
                                                    
                                                    // Updated checkmark color to mauve
                                                    if selectedAnswers[index] == answer {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(Color(red: 0.8, green: 0.6, blue: 0.7)) // Lighter mauve color
                                                    }
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    selectedAnswers[index] == answer ? 
                                                    selectedBeige :  // Much darker when selected
                                                    beige   // Regular beige when not selected
                                                )
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(beige, lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .cornerRadius(15)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 60) // Reduced from 80 to 60 to bring content closer to button
                    }
                }
                
                Spacer()
                
                // Overlay for Submit button
                VStack {
                    Spacer()
                    ZStack {
                        // Background blur
                        Rectangle()
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.95))
                            .frame(height: 100)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: -5)
                        
                        // Submit button
                        Button(action: {
                            calculateScore()
                        }) {
                            Text("Submit Answers")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 200)
                                .padding()
                                .background(Color(red: 0.6, green: 0.4, blue: 0.5))
                                .cornerRadius(10)
                        }
                    }
                }
                .ignoresSafeArea()
                
                NavigationLink(
                    destination: QuizSummaryView(
                        score: finalScore,
                        totalQuestions: viewModel.questions.count,
                        answeredQuestions: answeredQuestions,
                        timedOut: quizTimedOut
                    ).navigationBarHidden(true),
                    isActive: $showingSummary
                ) {
                    EmptyView()
                }
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                calculateScore()  // Calculate score for answered questions
                quizTimedOut = true  // Set the flag
                showingSummary = true  // Show summary view
            }
        }
        .onAppear {
            viewModel.fetchQuestions(
                amount: Int(numberOfQuestions) ?? 10,
                category: category,
                difficulty: difficulty.lowercased(),
                type: type
            )
        }
        .navigationBarHidden(true)
    }
    
    private func timeString(from seconds: Int) -> String {
        if seconds >= 3600 {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            let seconds = (seconds % 3600) % 60
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            let minutes = seconds / 60
            let seconds = seconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func calculateScore() {
        finalScore = 0
        answeredQuestions = []
        
        for (index, question) in viewModel.questions.enumerated() {
            let userAnswer = selectedAnswers[index] ?? "Not answered"
            answeredQuestions.append((
                question: question.question
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&#039;", with: "'")
                    .replacingOccurrences(of: "&eacute;", with: "é")
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&acute;", with: "´")
                    .replacingOccurrences(of: "&grave;", with: "`")
                    .replacingOccurrences(of: "&ldquo;", with: "\"")
                    .replacingOccurrences(of: "&rdquo;", with: "\"")
                    .replacingOccurrences(of: "&lsquo;", with: "'")
                    .replacingOccurrences(of: "&rsquo;", with: "'")
                    .replacingOccurrences(of: "&ndash;", with: "–")
                    .replacingOccurrences(of: "&mdash;", with: "—")
                ,
                userAnswer: userAnswer,
                correctAnswer: question.correct_answer
            ))
            
            if userAnswer == question.correct_answer {
                finalScore += 1
            }
        }
        showingSummary = true  // This triggers the sheet presentation
    }
}

struct QuizSummaryView: View {
    let score: Int
    let totalQuestions: Int
    let answeredQuestions: [(question: String, userAnswer: String, correctAnswer: String)]
    let timedOut: Bool
    @Environment(\.dismiss) var dismiss
    @State private var navigateToHome = false
    
    let beige = Color(red: 0.65, green: 0.60, blue: 0.55) // Add the beige color
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.15, green: 0.15, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Text("Quiz Completed!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 40)
                        
                        // Only show timeout message if the quiz actually timed out
                        if timedOut && !answeredQuestions.contains(where: { $0.userAnswer != "Not answered" }) {
                            Text("Time's up! Got to be quicker than that!")
                                .font(.headline)
                                .foregroundColor(Color(red: 1, green: 0.3, blue: 0.3)) // Brighter red
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                        }
                        
                        Text("You got \(score) out of \(totalQuestions) correct.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Add percentage score with consistent mauve color
                        Text("Score: \(Int(Double(score) / Double(totalQuestions) * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.5)) // Mauve color
                            .padding(.vertical, 10)
                        
                        ForEach(answeredQuestions.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Q\(index + 1): \(answeredQuestions[index].question)")
                                    .foregroundColor(.black) // Changed to black for better contrast on beige
                                    .fontWeight(.medium) // Added medium weight
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(minHeight: 60)
                                    .multilineTextAlignment(.leading)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your answer: \(answeredQuestions[index].userAnswer)")
                                        .foregroundColor(answeredQuestions[index].userAnswer == answeredQuestions[index].correctAnswer ? 
                                            Color(red: 0, green: 0.45, blue: 0) :  // Darker green (was 0.6)
                                            Color(red: 0.6, green: 0, blue: 0))    // Darker red (was 0.8)
                                        .fontWeight(.semibold)  // Changed from medium to semibold
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                    
                                    Text("Correct answer: \(answeredQuestions[index].correctAnswer)")
                                        .foregroundColor(Color(red: 0, green: 0.45, blue: 0))  // Matching darker green
                                        .fontWeight(.semibold)  // Changed from medium to semibold
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 160)
                            .background(beige)
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                        }
                        
                        // Add bottom padding to account for the overlay button
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding()
                }
                
                // Overlay for Finish button
                VStack {
                    Spacer()
                    ZStack {
                        // Background blur
                        Rectangle()
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.95))
                            .frame(height: 100)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: -5)
                        
                        // Finish button
                        NavigationLink(destination: ContentView()
                            .navigationBarHidden(true), isActive: $navigateToHome) {
                            Text("Finish")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 200)
                                .padding()
                                .background(Color(red: 0.6, green: 0.4, blue: 0.5))
                                .cornerRadius(10)
                        }
                    }
                }
                .ignoresSafeArea()
            }
        }
        .navigationBarHidden(true)
    }
}

