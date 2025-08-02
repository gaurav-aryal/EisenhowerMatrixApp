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
            case .urgentImportant: return "exclamationmark.triangle.fill"
            case .urgentNotImportant: return "clock.fill"
            case .notUrgentImportant: return "star.fill"
            case .notUrgentNotImportant: return "minus.circle.fill"
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
            // Urgent & Important - 2 tasks
            TaskItem(title: "Deadline project", description: "Complete urgent project", priority: .urgentImportant),
            TaskItem(title: "Team meeting", description: "Prepare for meeting", priority: .urgentImportant),
            
            // Urgent & Not Important - 2 tasks
            TaskItem(title: "Email responses", description: "Reply to emails", priority: .urgentNotImportant),
            TaskItem(title: "Phone calls", description: "Return calls", priority: .urgentNotImportant),
            
            // Not Urgent & Important - 2 tasks
            TaskItem(title: "Strategic planning", description: "Plan goals", priority: .notUrgentImportant),
            TaskItem(title: "Skill development", description: "Learn technology", priority: .notUrgentImportant),
            
            // Not Urgent & Not Important - 2 tasks
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
                    
                    Text("2 tasks per category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Matrix Grid
                VStack(spacing: 20) {
                    // Top row: Urgent quadrants
                    HStack(spacing: 12) {
                        matrixQuadrant(title: "Urgent & Important", subtitle: "Do First", priority: .urgentImportant, color: .red)
                        matrixQuadrant(title: "Urgent & Not Important", subtitle: "Delegate", priority: .urgentNotImportant, color: .orange)
                    }
                    
                    // Bottom row: Not Urgent quadrants (centered)
                    HStack(spacing: 12) {
                        Spacer()
                        matrixQuadrant(title: "Not Urgent & Important", subtitle: "Schedule", priority: .notUrgentImportant, color: .blue)
                        matrixQuadrant(title: "Not Urgent & Not Important", subtitle: "Eliminate", priority: .notUrgentNotImportant, color: .gray)
                        Spacer()
                    }
                }
                .padding()
                
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
                HStack {
                    Image(systemName: priority.icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    Text("\(taskManager.tasksForPriority(priority).count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(color)
                        .clipShape(Circle())
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            .padding(12)
            .frame(height: 120)
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
