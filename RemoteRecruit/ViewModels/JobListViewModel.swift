//
//  JobListViewModel.swift
//  RemoteRecruit
//
//  Created by Saurabh Jaiswal on 07/06/26.
//

import Foundation

enum ViewState {
    case idle
    case loading
    case success
    case empty
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
