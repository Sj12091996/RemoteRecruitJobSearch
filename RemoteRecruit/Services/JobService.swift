//
//  JobService.swift
//  RemoteRecruit
//
//  Created by Saurabh Jaiswal on 07/06/26.
//

import Foundation

// Abstraction over the API layer — makes it easy to swap in a mock during tests
protocol JobServiceProtocol {
    func fetchJobs(search: String?) async throws -> [Job]
}

// Covers the failure cases we can reasonably expect from a network call
enum NetworkError: LocalizedError {
    case invalidURL
    case decodingFailed
    case serverError(Int)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .decodingFailed: return "Failed to decode response."
        case .serverError(let code): return "Server error: \(code)."
        case .unknown(let error): return error.localizedDescription
        }
    }
}

class JobService: JobServiceProtocol {
    
    private let baseURL = "https://remotive.com/api/remote-jobs"
    
    // We fetch all jobs and let the ViewModel handle filtering client-side
    // The Remotive API's ?search= param is unreliable so we ignore it
    func fetchJobs(search: String? = nil) async throws -> [Job] {
        guard let url = URL(string: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            let decoded = try JSONDecoder().decode(JobsResponse.self, from: data)
            return decoded.jobs
        } catch let error as NetworkError {
            // Re-throw our own errors as-is so they aren't double-wrapped
            throw error
        } catch is DecodingError {
            throw NetworkError.decodingFailed
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
