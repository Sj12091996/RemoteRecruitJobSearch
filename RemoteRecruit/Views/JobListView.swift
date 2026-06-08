//
//  ContentView.swift
//  RemoteRecruit
//
//  Created by Saurabh Jaiswal on 05/06/26.
//


import SwiftUI

struct JobListView: View {
    
    @StateObject private var viewModel = JobListViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.viewState {
                case .idle, .loading:
                    // Loading State
                    LoadingView()
                case .success:
                    jobList
                case .empty:
                    // Shown when the search query returns no matches
                    EmptyStateView(message: "No jobs found for \"\(viewModel.searchText)\"")
                case .error(let message):
                    // Passes retry closure so the error view can trigger a fresh fetch
                    ErrorView(message: message) {
                        Task { await viewModel.retry() }
                    }
                }
            }
            .navigationTitle("Remote Jobs")
            // Binds directly to viewModel.searchText — didSet triggers client-side filtering
            .searchable(text: $viewModel.searchText, prompt: "Search by title or company")
            // Kicks off the initial fetch when the view appears
            .task {
                await viewModel.loadJobs()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // Extracted to keep body readable — renders the flat job list on success
    private var jobList: some View {
        List(viewModel.jobs) { job in
            NavigationLink(destination: JobDetailView(viewModel: JobDetailViewModel(job: job))) {
                JobRowView(job: job)
            }
        }
        .listStyle(.plain)
    }
}



