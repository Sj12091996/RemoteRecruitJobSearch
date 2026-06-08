//
//  JobRowView.swift
//  RemoteRecruit
//
//  Created by Saurabh Jaiswal on 07/06/26.
//

import SwiftUI

// Single row in the job list — shows the key details at a glance
struct JobRowView: View {
    
    let job: Job
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(job.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(job.company_name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Label(job.locationDisplay, systemImage: "location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !job.salaryDisplay.isEmpty && job.salaryDisplay != "Not specified" {
                    Label(job.salaryDisplay, systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            if let type = job.job_type {
                Text(type)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
    }
}
