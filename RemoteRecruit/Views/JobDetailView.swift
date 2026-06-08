//
//  JobListView.swift
//  RemoteRecruit
//
//  Created by Saurabh Jaiswal on 07/06/26.
//

import SwiftUI

struct JobDetailView: View {
    
    @ObservedObject var viewModel: JobDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(viewModel.company)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Info Cards
                HStack(spacing: 12) {
                    InfoCard(icon: "location.fill", label: "Location", value: viewModel.location)
                    InfoCard(icon: "dollarsign.circle.fill", label: "Salary", value: viewModel.salary)
                }
                
                HStack(spacing: 12) {
                    InfoCard(icon: "briefcase.fill", label: "Job Type", value: viewModel.jobType)
                }
                
                // Tags
                if !viewModel.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills")
                            .font(.headline)
                        
                        FlowLayout(tags: viewModel.tags)
                    }
                }
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Job Description")
                        .font(.headline)
                    
                    // Strip basic HTML tags for display
                    Text(viewModel.description.strippedHTML)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                
                // Apply Button
                if let url = viewModel.jobURL {
                    Link(destination: url) {
                        HStack {
                            Spacer()
                            Text("Apply Now")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding()
                            Spacer()
                        }
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - InfoCard
struct InfoCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - FlowLayout for tags
struct FlowLayout: View {
    let tags: [String]
    
    var body: some View {
        // Simple wrapping tag layout
        var width: CGFloat = 0
        var rows: [[String]] = [[]]
        
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                        .alignmentGuide(.leading) { d in
                            if width + d.width > geo.size.width {
                                width = 0
                            }
                            let result = -width
                            width += d.width + 8
                            return result
                        }
                }
            }
        }
        .frame(height: 80)
    }
}

// MARK: - HTML Strip Extension
extension String {
    // Removes HTML tags from job descriptions returned by the Remotive API.
    // Tries NSAttributedString first for accurate parsing; falls back to regex if that fails.
    var strippedHTML: String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }
        // Fallback: basic regex strip
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
