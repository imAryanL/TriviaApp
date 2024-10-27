import Foundation
import SwiftUI

class TriviaManager: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isCategoriesLoading = false
    @Published var categoriesError: String?
    
    init() {
        fetchCategories()
    }
    
    func fetchCategories() {
        guard let url = URL(string: "https://opentdb.com/api_category.php") else {
            self.categoriesError = "Invalid URL"
            return
        }
        
        isCategoriesLoading = true
        categoriesError = nil
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isCategoriesLoading = false
                
                if let error = error {
                    self.categoriesError = "Failed to fetch categories: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.categoriesError = "No data received"
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(CategoryResponse.self, from: data)
                    self.categories = [Category(id: 0, name: "Any Category")] + decodedResponse.triviaCategories
                } catch {
                    self.categoriesError = "Failed to decode categories: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
}

struct CategoryResponse: Codable {
    let triviaCategories: [Category]
    
    enum CodingKeys: String, CodingKey {
        case triviaCategories = "trivia_categories"
    }
}
