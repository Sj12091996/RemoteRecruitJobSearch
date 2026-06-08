//
//  JobListViewModel.swift
//  RemoteRecruit
//
//  Created by Saurabh Jaiswal on 07/06/26.
//

import Foundation

// Drives the UI — views switch on this to show the right screen
enum ViewState {
    case idle        // initial state, nothing fetched yet
    case loading     // network request in flight
    case success     // jobs loaded and visible
    case empty       // request succeeded but no results matched
    case error(String)
}

@MainActor
class JobListViewModel: ObservableObject {
    
    @Published var jobs: [Job] = []
    @Published var searchText: String = "" {
        didSet { filterJobs() }
    }
    @Published var viewState: ViewState = .idle
    
    private let service: JobServiceProtocol
    private var allJobs: [Job] = []  // full list from API, never modified
    
    init(service: JobServiceProtocol = JobService()) {
        self.service = service
    }
    
    // Fetches the full job list and hands off to filterJobs()
    func loadJobs() async {
        viewState = .loading
        do {
            let result = try await service.fetchJobs(search: nil)
            allJobs = result
            filterJobs()
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
    
    // Filters allJobs by title or company name against the current search query.
    // Client-side filtering — works reliably unlike the API's search param
    private func filterJobs() {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        
        if query.isEmpty {
            jobs = allJobs
        } else {
            jobs = allJobs.filter {
                $0.title.lowercased().contains(query) ||
                $0.company_name.lowercased().contains(query)
            }
        }
        
        viewState = jobs.isEmpty ? .empty : .success
    }
    
    func retry() async {
        await loadJobs()
    }
}
