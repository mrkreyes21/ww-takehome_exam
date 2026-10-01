import Foundation

protocol DataLoadServiceProtocol {
    func loadSubmissions(from resourceName: String) throws -> [Submission]
}

enum DataLoadError: LocalizedError {
    case fileNotFound(String)
    case unreadableData(Error)
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Could not locate '\(filename).json' in the application bundle."
        case .unreadableData(let error):
            return "Failed to read data from file: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode submissions data: \(error.localizedDescription)"
        }
    }
}

final class DataLoadService: DataLoadServiceProtocol {
    private let bundle: Bundle
    
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    func loadSubmissions(from resourceName: String = "submissions") throws -> [Submission] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw DataLoadError.fileNotFound(resourceName)
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DataLoadError.unreadableData(error)
        }
        
        do {
            let decoder = JSONDecoder()
            let submissions = try decoder.decode([Submission].self, from: data)
            return submissions
        } catch {
            throw DataLoadError.decodingFailed(error)
        }
    }
}
