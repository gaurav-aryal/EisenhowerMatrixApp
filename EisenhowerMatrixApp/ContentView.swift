//
//  ContentView.swift
//  EisenhowerMatrixApp
//
//  Created by user280681 on 8/2/25.
//

import SwiftUI

// MARK: - Task Model
struct Task: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var priority: Priority
    var isCompleted: Bool = false
    var dateCreated: Date = Date()
    
    enum Priority: String, CaseIterable, Codable {
        case urgentImportant = "Urgent & Important"
        case urgentNotImportant = "Urgent & Not Important"
        case notUrgentImportant = "Not Urgent & Important"
        case notUrgentNotImportant = "Not Urgent & Not Important"
        
        var color: Color {
            switch self {
            case .urgentImportant:
                return .red
            case .urgentNotImportant:
                return .orange
            case .notUrgentImportant:
                return .blue
            case .notUrgentNotImportant:
                return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .urgentImportant:
                return "exclamationmark.triangle.fill"
            case .urgentNotImportant:
                return "clock.fill"
            case .notUrgentImportant:
                return "star.fill"
            case .notUrgentNotImportant:
                return "minus.circle.fill"
            }
        }
    }
}

// MARK: - Task Manager
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    
    init() {
        loadSampleData()
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func tasksForPriority(_ priority: Task.Priority) -> [Task] {
        return tasks.filter { $0.priority == priority }
    }
    
    private func loadSampleData() {
        tasks = [
            Task(title: "Deadline project", description: "Complete the urgent project", priority: .urgentImportant),
            Task(title: "Team meeting", description: "Prepare for tomorrow's meeting", priority: .urgentImportant),
            Task(title: "Email responses", description: "Reply to urgent emails", priority: .urgentNotImportant),
            Task(title: "Phone calls", description: "Return urgent calls", priority: .urgentNotImportant),
            Task(title: "Strategic planning", description: "Plan next quarter goals", priority: .notUrgentImportant),
            Task(title: "Skill development", description: "Learn new technology", priority: .notUrgentImportant),
            Task(title: "Social media", description: "Check social media", priority: .notUrgentNotImportant),
            Task(title: "Some interruptions", description: "Handle minor interruptions", priority: .notUrgentNotImportant)
        ]
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var selectedPriority: Task.Priority?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Matrix Grid
                matrixGridView
                
                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(taskManager: taskManager)
            }
            .sheet(item: $selectedPriority) { priority in
                PriorityDetailView(taskManager: taskManager, priority: priority)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Eisenhower Matrix")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            Text("Prioritize your tasks effectively")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var matrixGridView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Quadrant 1: Urgent & Important
                matrixQuadrant(
                    title: "Urgent & Important",
                    subtitle: "Do First",
                    priority: .urgentImportant,
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                // Quadrant 2: Urgent & Not Important
                matrixQuadrant(
                    title: "Urgent & Not Important",
                    subtitle: "Delegate",
                    priority: .urgentNotImportant,
                    color: .orange,
                    icon: "clock.fill"
                )
            }
            
            HStack(spacing: 12) {
                // Quadrant 3: Not Urgent & Important
                matrixQuadrant(
                    title: "Not Urgent & Important",
                    subtitle: "Schedule",
                    priority: .notUrgentImportant,
                    color: .blue,
                    icon: "star.fill"
                )
                
                // Quadrant 4: Not Urgent & Not Important
                matrixQuadrant(
                    title: "Not Urgent & Not Important",
                    subtitle: "Eliminate",
                    priority: .notUrgentNotImportant,
                    color: .gray,
                    icon: "minus.circle.fill"
                )
            }
        }
        .padding()
    }
    
    private func matrixQuadrant(
        title: String,
        subtitle: String,
        priority: Task.Priority,
        color: Color,
        icon: String
    ) -> some View {
        Button(action: { selectedPriority = priority }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
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
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            .padding(12)
            .frame(height: 120)
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Priority Detail View
struct PriorityDetailView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: Task.Priority
    @Environment(\.presentationMode) var presentationMode
    
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
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Add Task") {
                    // Add task functionality
                }
            )
        }
    }
    
    private func getSubtitle(for priority: Task.Priority) -> String {
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
    let task: Task
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

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority: Task.Priority = .urgentImportant
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                    .foregroundColor(priority.color)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    let newTask = Task(title: title, description: description, priority: selectedPriority)
                    taskManager.addTask(newTask)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// MARK: - Extensions
extension Task.Priority: Identifiable {
    var id: String { rawValue }
}

#Preview {
    ContentView()
}
