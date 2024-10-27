import SwiftUI

struct QuestionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = QuestionViewModel()
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer = ""
    @State private var score = 0
    @State private var timeRemaining: Int
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Add these properties
    let numberOfQuestions: String
    let category: String
    let difficulty: String
    let type: String
    let timerDuration: String
    let darkerGray = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    init(numberOfQuestions: String, category: String, difficulty: String, type: String, timerDuration: String) {
        self.numberOfQuestions = numberOfQuestions
        self.category = category
        self.difficulty = difficulty
        self.type = type
        self.timerDuration = timerDuration
        
        // Convert timer duration string to seconds
        let duration = timerDuration.components(separatedBy: " ")[0]
        if timerDuration.contains("hour") {
            _timeRemaining = State(initialValue: 3600)
        } else {
            _timeRemaining = State(initialValue: Int(duration) ?? 30)
        }
    }
    
    var body: some View {
        ZStack {
            darkerGray
                .ignoresSafeArea()  // This ensures the background color extends to the edges
            
            VStack {
                // Timer and Progress bar at top
                HStack {
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 4)
                }
                .padding(.top, 1) // Reduced top padding to minimize white space
                
                if viewModel.isLoading {
                    ProgressView("Loading questions...")
                        .foregroundColor(.white)
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                        Button("Try Again") {
                            viewModel.fetchQuestions(
                                amount: Int(numberOfQuestions) ?? 10,
                                category: category,
                                difficulty: difficulty.lowercased(),
                                type: type
                            )
                        }
                        .foregroundColor(.blue)
                    }
                } else if !viewModel.questions.isEmpty {
                    VStack(spacing: 20) {
                        Text("Question \(currentQuestionIndex + 1) of \(viewModel.questions.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(viewModel.questions[currentQuestionIndex].category)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(viewModel.questions[currentQuestionIndex].question
                            .replacingOccurrences(of: "&quot;", with: "\"")
                            .replacingOccurrences(of: "&#039;", with: "'")
                        )
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.getAnswerChoices(for: currentQuestionIndex), id: \.self) { answer in
                                Button(action: {
                                    selectedAnswer = answer
                                }) {
                                    Text(answer
                                        .replacingOccurrences(of: "&quot;", with: "\"")
                                        .replacingOccurrences(of: "&#039;", with: "'")
                                    )
                                    .foregroundColor(selectedAnswer == answer ? .white : .blue)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(selectedAnswer == answer ? Color.blue : darkerGray)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                Button("Go Back") {
                    dismiss()
                }
                .foregroundColor(.blue)
                .padding()
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Time's up - handle accordingly
                dismiss()
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
        .navigationBarHidden(true) // This ensures no navigation bar is shown
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
}

extension QuestionViewModel {
    func getAnswerChoices(for index: Int) -> [String] {
        guard index < shuffledAnswers.count else { return [] }
        return shuffledAnswers[index]
    }
}

class QuestionViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var isLoading = false
    @Published var error: String?
    private var shuffledAnswers: [[String]] = []  // Add this to store shuffled answers
    
    struct Question: Codable, Identifiable {
        let id = UUID()
        let category: String
        let type: String
        let difficulty: String
        let question: String
        let correct_answer: String
        let incorrect_answers: [String]
    }
    
    struct TriviaResponse: Codable {
        let response_code: Int
        let results: [Question]
    }
    
    func fetchQuestions(amount: Int, category: String, difficulty: String, type: String) {
        isLoading = true
        error = nil
        shuffledAnswers = []  // Reset shuffled answers when fetching new questions
        
        let categoryId = getCategoryId(for: category)
        let typeParam = convertTypeToApiFormat(type)
        
        var urlComponents = URLComponents(string: "https://opentdb.com/api.php")!
        urlComponents.queryItems = [
            URLQueryItem(name: "amount", value: String(amount))
        ]
        
        if categoryId != 0 {
            urlComponents.queryItems?.append(URLQueryItem(name: "category", value: String(categoryId)))
        }
        
        if difficulty != "any difficulty" {
            urlComponents.queryItems?.append(URLQueryItem(name: "difficulty", value: difficulty.lowercased()))
        }
        
        if typeParam != "any" {
            urlComponents.queryItems?.append(URLQueryItem(name: "type", value: typeParam))
        }
        
        guard let url = urlComponents.url else {
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
                    let response = try JSONDecoder().decode(TriviaResponse.self, from: data)
                    if response.response_code == 0 {
                        self?.questions = response.results
                        // Shuffle answers once when questions are loaded
                        self?.shuffledAnswers = response.results.map { question in
                            var choices = question.incorrect_answers
                            choices.append(question.correct_answer)
                            return choices.shuffled()
                        }
                    } else {
                        self?.error = self?.getErrorMessage(for: response.response_code)
                    }
                } catch {
                    self?.error = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func getCategoryId(for categoryName: String) -> Int {
        let categoryMap = [
            "Any Category": 0,
            "General Knowledge": 9,
            "Entertainment: Books": 10,
            "Entertainment: Film": 11,
            "Entertainment: Music": 12,
            "Entertainment: Musicals & Theatres": 13,
            "Entertainment: Television": 14,
            "Entertainment: Video Games": 15,
            "Entertainment: Board Games": 16,
            "Science & Nature": 17,
            "Science: Computers": 18,
            "Science: Mathematics": 19,
            "Mythology": 20,
            "Sports": 21,
            "Geography": 22,
            "History": 23,
            "Politics": 24,
            "Art": 25,
            "Celebrities": 26,
            "Animals": 27,
            "Vehicles": 28,
            "Entertainment: Comics": 29,
            "Science: Gadgets": 30,
            "Entertainment: Japanese Anime & Manga": 31,
            "Entertainment: Cartoon & Animations": 32
        ]
        return categoryMap[categoryName] ?? 0
    }
    
    private func convertTypeToApiFormat(_ type: String) -> String {
        switch type {
        case "Multiple Choice":
            return "multiple"
        case "True or False":
            return "boolean"
        default:
            return "any"
        }
    }
    
    private func getErrorMessage(for code: Int) -> String {
        switch code {
        case 1:
            return "No results found. Try different parameters."
        case 2:
            return "Invalid parameter provided."
        case 3:
            return "Session token not found."
        case 4:
            return "Session token has retrieved all possible questions."
        default:
            return "Unknown error occurred."
        }
    }
}

// At the bottom of QuestionView.swift
struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView(
            numberOfQuestions: "10",
            category: "Any Category",
            difficulty: "Medium",
            type: "Multiple Choice",
            timerDuration: "30 seconds"
        )
    }
}
