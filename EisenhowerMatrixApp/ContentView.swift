//
//  ContentView.swift
//  EisenhowerMatrixApp
//
//  Created by user280681 on 8/2/25.
//

import SwiftUI

struct TaskItem: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var priority: Priority
    var isCompleted: Bool = false
    var dateCreated: Date = Date()
    
    enum Priority: String, CaseIterable {
        case urgentImportant = "Urgent & Important"
        case urgentNotImportant = "Urgent & Not Important"
        case notUrgentImportant = "Not Urgent & Important"
        case notUrgentNotImportant = "Not Urgent & Not Important"
        
        var color: Color {
            switch self {
            case .urgentImportant: return .red
            case .urgentNotImportant: return .orange
            case .notUrgentImportant: return .blue
            case .notUrgentNotImportant: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .urgentImportant:
                return "exclamationmark.triangle.fill"
            case .urgentNotImportant:
                return "⏰"
            case .notUrgentImportant:
                return "star.fill"
            case .notUrgentNotImportant:
                return "🗑️"
            }
        }
    }
}

class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    
    init() {
        loadSampleData()
    }
    
    func loadSampleData() {
        tasks = [
            // Urgent & Important - 7 tasks (will show 5 + "More...")
            TaskItem(title: "Deadline project", description: "Complete urgent project", priority: .urgentImportant),
            TaskItem(title: "Team meeting", description: "Prepare for meeting", priority: .urgentImportant),
            TaskItem(title: "Client presentation", description: "Prepare slides", priority: .urgentImportant),
            TaskItem(title: "Budget review", description: "Review quarterly budget", priority: .urgentImportant),
            TaskItem(title: "Emergency call", description: "Handle urgent client call", priority: .urgentImportant),
            TaskItem(title: "Project deadline", description: "Finalize project deliverables", priority: .urgentImportant),
            TaskItem(title: "Critical bug fix", description: "Fix production bug", priority: .urgentImportant),
            
            // Urgent & Not Important - 3 tasks (will show all 3)
            TaskItem(title: "Email responses", description: "Reply to emails", priority: .urgentNotImportant),
            TaskItem(title: "Phone calls", description: "Return calls", priority: .urgentNotImportant),
            TaskItem(title: "Meeting prep", description: "Prepare for team meeting", priority: .urgentNotImportant),
            
            // Not Urgent & Important - 4 tasks (will show all 4)
            TaskItem(title: "Strategic planning", description: "Plan goals", priority: .notUrgentImportant),
            TaskItem(title: "Skill development", description: "Learn technology", priority: .notUrgentImportant),
            TaskItem(title: "Network building", description: "Connect with colleagues", priority: .notUrgentImportant),
            TaskItem(title: "Process improvement", description: "Optimize workflows", priority: .notUrgentImportant),
            
            // Not Urgent & Not Important - 2 tasks (will show all 2)
            TaskItem(title: "Social media", description: "Check updates", priority: .notUrgentNotImportant),
            TaskItem(title: "Some interruptions", description: "Handle distractions", priority: .notUrgentNotImportant)
        ]
    }
    
    func tasksForPriority(_ priority: TaskItem.Priority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority }
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
}

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var selectedPriority: TaskItem.Priority?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Eisenhower Matrix")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding()
                
                // Matrix Grid
                VStack(spacing: 0) {
                    // Top section: Urgent quadrants
                    HStack(spacing: 12) {
                        matrixQuadrant(title: "Urgent & Important", subtitle: "Do First", priority: .urgentImportant, color: .red)
                        matrixQuadrant(title: "Urgent & Not Important", subtitle: "Delegate", priority: .urgentNotImportant, color: .orange)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Center section with proper spacing
                    Spacer()
                        .frame(height: 80)
                    
                    // Bottom section: Not Urgent quadrants (truly centered)
                    HStack {
                        Spacer()
                        HStack(spacing: 12) {
                            matrixQuadrant(title: "Not Urgent & Important", subtitle: "Schedule", priority: .notUrgentImportant, color: .blue)
                            matrixQuadrant(title: "Not Urgent & Not Important", subtitle: "Eliminate", priority: .notUrgentNotImportant, color: .gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 80)
                }
                
                Spacer()
            }
        }
        .sheet(item: $selectedPriority) { priority in
            PriorityDetailView(taskManager: taskManager, priority: priority)
        }
    }
    
    private func matrixQuadrant(title: String, subtitle: String, priority: TaskItem.Priority, color: Color) -> some View {
        Button(action: { selectedPriority = priority }) {
            VStack(spacing: 8) {
                // Header with proper alignment
                HStack {
                    Image(systemName: priority.icon)
                        .foregroundColor(color)
                        .font(.title2)
                        .frame(width: 24, height: 24, alignment: .center)
                    
                    Spacer()
                    
                    Text("\(taskManager.tasksForPriority(priority).count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(color)
                        .clipShape(Circle())
                }
                .padding(.horizontal, 4)
                
                // Title and subtitle
                VStack(spacing: 3) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(color)
                        .lineLimit(1)
                }
                
                // Task list
                VStack(spacing: 3) {
                    let tasks = taskManager.tasksForPriority(priority)
                    ForEach(Array(tasks.prefix(5)), id: \.id) { task in
                        HStack(spacing: 6) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                                .font(.caption)
                                .frame(width: 14, height: 14)
                            
                            Text(task.title)
                                .font(.caption)
                                .lineLimit(1)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(task.isCompleted ? .secondary : .primary)
                            
                            Spacer()
                        }
                    }
                    
                    // Show "More..." only when there are more than 5 tasks
                    if tasks.count > 5 {
                        Text("More...")
                            .font(.caption)
                            .foregroundColor(color)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 4)
                
                Spacer()
            }
            .padding(12)
            .frame(width: 160, height: 180)
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PriorityDetailView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskItem.Priority
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(taskManager.tasksForPriority(priority)) { task in
                    HStack {
                        Button(action: { taskManager.toggleTaskCompletion(task) }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .strikethrough(task.isCompleted)
                            Text(task.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle(priority.rawValue)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension TaskItem.Priority: Identifiable {
    var id: String { rawValue }
}

#Preview {
    ContentView()
}
