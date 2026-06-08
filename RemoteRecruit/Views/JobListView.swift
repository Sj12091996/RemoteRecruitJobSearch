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
                    LoadingView()
                case .success:
                    jobList
                case .empty:
                    EmptyStateView(message: "No jobs found for \"\(viewModel.searchText)\"")
                case .error(let message):
                    ErrorView(message: message) {
                        Task { await viewModel.retry() }
                    }
                }
            }
            .navigationTitle("Remote Jobs")
            .searchable(text: $viewModel.searchText, prompt: "Search by title or company")
            .task {
                await viewModel.loadJobs()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var jobList: some View {
        List(viewModel.jobs) { job in
            NavigationLink(destination: JobDetailView(viewModel: JobDetailViewModel(job: job))) {
                JobRowView(job: job)
            }
        }
        .listStyle(.plain)
    }
}



