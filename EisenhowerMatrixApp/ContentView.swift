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

// MARK: - Data Manager
class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    
    init() {
        loadSampleData()
    }
    
    func addTask(title: String, description: String, priority: TaskItem.Priority) {
        let newTask = TaskItem(
            title: title,
            description: description,
            priority: priority
        )
        tasks.append(newTask)
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
    
    func toggleTaskCompletion(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func tasksForPriority(_ priority: TaskItem.Priority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskItem.Priority
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Priority")) {
                    HStack {
                        Image(systemName: priority.icon)
                            .foregroundColor(priority.color)
                        Text(priority.rawValue)
                            .foregroundColor(priority.color)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    taskManager.addTask(title: title, description: description, priority: priority)
                    dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// MARK: - Priority Detail View
struct PriorityDetailView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskItem.Priority
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: priority.icon)
                            .font(.title)
                            .foregroundColor(priority.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(priority.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(getSubtitle(for: priority))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(taskManager.tasksForPriority(priority).count) tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(taskManager.tasksForPriority(priority).filter { $0.isCompleted }.count) completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(priority.color.opacity(0.1))
                
                // Task List
                List {
                    ForEach(taskManager.tasksForPriority(priority)) { task in
                        TaskRowView(task: task, taskManager: taskManager)
                    }
                    .onDelete(perform: deleteTasks)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(priority.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") { dismiss() },
                trailing: Button("Add Task") {
                    // Add task functionality
                }
            )
        }
    }
    
    private func getSubtitle(for priority: TaskItem.Priority) -> String {
        switch priority {
        case .urgentImportant:
            return "Do First - These require immediate attention"
        case .urgentNotImportant:
            return "Delegate - These can be delegated to others"
        case .notUrgentImportant:
            return "Schedule - Plan these for later"
        case .notUrgentNotImportant:
            return "Eliminate - Consider removing these tasks"
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        let tasksToDelete = taskManager.tasksForPriority(priority)
        for index in offsets {
            taskManager.deleteTask(tasksToDelete[index])
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var taskManager: TaskManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { taskManager.toggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .strikethrough(task.isCompleted)
            }
            
            Spacer()
            
            Text(task.dateCreated, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

extension TaskItem.Priority: Identifiable {
    var id: String { rawValue }
}

#Preview {
    ContentView()
}
