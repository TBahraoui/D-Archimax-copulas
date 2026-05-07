/**
 * Todo List Application with Local Storage
 * Features: Add, Edit, Delete, Complete, Filter, Sort, Export/Import
 */

class TodoApp {
    constructor() {
        this.todos = [];
        this.currentFilter = 'all';
        this.currentSort = 'date-desc';
        this.editingId = null;
        this.init();
    }

    init() {
        this.loadFromStorage();
        this.attachEventListeners();
        this.render();
        this.updateStorageInfo();
    }

    /**
     * Storage Management
     */
    loadFromStorage() {
        try {
            const stored = localStorage.getItem('todos');
            this.todos = stored ? JSON.parse(stored) : [];
        } catch (error) {
            console.error('Error loading from storage:', error);
            this.showToast('Error loading tasks', 'error');
            this.todos = [];
        }
    }

    saveToStorage() {
        try {
            localStorage.setItem('todos', JSON.stringify(this.todos));
            this.updateStorageInfo();
        } catch (error) {
            console.error('Error saving to storage:', error);
            this.showToast('Error saving tasks', 'error');
        }
    }

    updateStorageInfo() {
        try {
            const used = new Blob(Object.values(localStorage)).size;
            const limit = 5 * 1024 * 1024; // 5MB typical limit
            const percentage = ((used / limit) * 100).toFixed(2);
            document.getElementById('storageInfo').textContent = 
                `Storage: ${(used / 1024).toFixed(1)}KB / ~${(limit / 1024 / 1024).toFixed(0)}MB (${percentage}%)`;
        } catch (error) {
            console.error('Error updating storage info:', error);
        }
    }

    /**
     * Event Listeners
     */
    attachEventListeners() {
        // Form submission
        document.getElementById('todoForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.addTodo();
        });

        // Filters
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.setFilter(e.target.closest('button')));
        });

        // Sorting
        document.getElementById('sortSelect').addEventListener('change', (e) => {
            this.currentSort = e.target.value;
            this.render();
        });

        // Action buttons
        document.getElementById('clearCompleted').addEventListener('click', () => this.clearCompleted());
        document.getElementById('exportBtn').addEventListener('click', () => this.exportTodos());
        document.getElementById('importBtn').addEventListener('click', () => {
            document.getElementById('fileInput').click();
        });
        document.getElementById('fileInput').addEventListener('change', (e) => this.importTodos(e));

        // Modal
        document.getElementById('closeModal').addEventListener('click', () => this.closeModal());
        document.getElementById('cancelBtn').addEventListener('click', () => this.closeModal());
        document.getElementById('editForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.saveEdit();
        });

        // Close modal on outside click
        window.addEventListener('click', (e) => {
            const modal = document.getElementById('editModal');
            if (e.target === modal) this.closeModal();
        });
    }

    /**
     * Todo Operations
     */
    addTodo() {
        const input = document.getElementById('todoInput');
        const priority = document.getElementById('prioritySelect').value;
        const text = input.value.trim();

        if (!text) {
            this.showToast('Please enter a task', 'warning');
            return;
        }

        if (text.length > 200) {
            this.showToast('Task must be less than 200 characters', 'warning');
            return;
        }

        const todo = {
            id: Date.now(),
            text,
            priority,
            completed: false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        this.todos.unshift(todo);
        this.saveToStorage();
        this.render();
        input.value = '';
        document.getElementById('prioritySelect').value = 'medium';
        this.showToast('Task added successfully', 'success');
    }

    deleteTodo(id) {
        if (!confirm('Are you sure you want to delete this task?')) return;

        this.todos = this.todos.filter(todo => todo.id !== id);
        this.saveToStorage();
        this.render();
        this.showToast('Task deleted', 'info');
    }

    toggleTodo(id) {
        const todo = this.todos.find(t => t.id === id);
        if (todo) {
            todo.completed = !todo.completed;
            todo.updatedAt = new Date().toISOString();
            this.saveToStorage();
            this.render();
        }
    }

    openEditModal(id) {
        const todo = this.todos.find(t => t.id === id);
        if (!todo) return;

        this.editingId = id;
        document.getElementById('editInput').value = todo.text;
        document.getElementById('editPrioritySelect').value = todo.priority;
        document.getElementById('editModal').classList.add('show');
        document.getElementById('editInput').focus();
    }

    closeModal() {
        document.getElementById('editModal').classList.remove('show');
        this.editingId = null;
    }

    saveEdit() {
        const todo = this.todos.find(t => t.id === this.editingId);
        if (!todo) return;

        const newText = document.getElementById('editInput').value.trim();
        const newPriority = document.getElementById('editPrioritySelect').value;

        if (!newText) {
            this.showToast('Task cannot be empty', 'warning');
            return;
        }

        if (newText.length > 200) {
            this.showToast('Task must be less than 200 characters', 'warning');
            return;
        }

        todo.text = newText;
        todo.priority = newPriority;
        todo.updatedAt = new Date().toISOString();
        this.saveToStorage();
        this.render();
        this.closeModal();
        this.showToast('Task updated successfully', 'success');
    }

    clearCompleted() {
        const completedCount = this.todos.filter(t => t.completed).length;
        if (completedCount === 0) {
            this.showToast('No completed tasks to clear', 'info');
            return;
        }

        if (!confirm(`Delete ${completedCount} completed task(s)?`)) return;

        this.todos = this.todos.filter(todo => !todo.completed);
        this.saveToStorage();
        this.render();
        this.showToast('Completed tasks cleared', 'info');
    }

    /**
     * Filtering and Sorting
     */
    setFilter(button) {
        document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
        button.classList.add('active');
        this.currentFilter = button.dataset.filter;
        this.render();
    }

    getFilteredTodos() {
        let filtered = this.todos;

        switch (this.currentFilter) {
            case 'active':
                filtered = filtered.filter(todo => !todo.completed);
                break;
            case 'completed':
                filtered = filtered.filter(todo => todo.completed);
                break;
            case 'high-priority':
                filtered = filtered.filter(todo => todo.priority === 'high');
                break;
        }

        return this.sortTodos(filtered);
    }

    sortTodos(todos) {
        const sorted = [...todos];

        switch (this.currentSort) {
            case 'date-asc':
                sorted.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
                break;
            case 'priority':
                const priorityOrder = { high: 1, medium: 2, low: 3 };
                sorted.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
                break;
            case 'alphabetical':
                sorted.sort((a, b) => a.text.localeCompare(b.text));
                break;
            case 'date-desc':
            default:
                sorted.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        }

        return sorted;
    }

    /**
     * Statistics
     */
    updateStats() {
        const total = this.todos.length;
        const completed = this.todos.filter(t => t.completed).length;
        const remaining = total - completed;
        const percentage = total === 0 ? 0 : Math.round((completed / total) * 100);

        document.getElementById('totalTasks').textContent = total;
        document.getElementById('completedCount').textContent = completed;
        document.getElementById('remainingCount').textContent = remaining;
        document.getElementById('progressPercent').textContent = `${percentage}%`;
        document.getElementById('progressFill').style.width = `${percentage}%`;
    }

    /**
     * Rendering
     */
    render() {
        this.updateStats();
        this.renderTodos();
    }

    renderTodos() {
        const todoList = document.getElementById('todoList');
        const emptyState = document.getElementById('emptyState');
        const filteredTodos = this.getFilteredTodos();

        if (filteredTodos.length === 0) {
            todoList.innerHTML = '';
            emptyState.classList.add('show');
            return;
        }

        emptyState.classList.remove('show');
        todoList.innerHTML = filteredTodos.map(todo => this.createTodoElement(todo)).join('');

        // Attach event listeners to dynamically created elements
        document.querySelectorAll('.checkbox').forEach(checkbox => {
            checkbox.addEventListener('change', (e) => this.toggleTodo(parseInt(e.target.dataset.id)));
        });

        document.querySelectorAll('.edit-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.openEditModal(parseInt(e.target.closest('button').dataset.id)));
        });

        document.querySelectorAll('.delete-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.deleteTodo(parseInt(e.target.closest('button').dataset.id)));
        });
    }

    createTodoElement(todo) {
        const createdDate = new Date(todo.createdAt).toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });

        return `
            <li class="todo-item priority-${todo.priority} ${todo.completed ? 'completed' : ''}">
                <input
                    type="checkbox"
                    class="checkbox"
                    data-id="${todo.id}"
                    ${todo.completed ? 'checked' : ''}
                />
                <div class="todo-content">
                    <span class="todo-text">${this.escapeHtml(todo.text)}</span>
                    <span class="todo-date">Created: ${createdDate}</span>
                </div>
                <span class="priority-badge ${todo.priority}">${todo.priority}</span>
                <div class="todo-actions">
                    <button class="action-btn edit-btn" data-id="${todo.id}" title="Edit task">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="action-btn delete-btn" data-id="${todo.id}" title="Delete task">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </li>
        `;
    }

    /**
     * Export/Import
     */
    exportTodos() {
        if (this.todos.length === 0) {
            this.showToast('No tasks to export', 'warning');
            return;
        }

        const dataStr = JSON.stringify(this.todos, null, 2);
        const dataBlob = new Blob([dataStr], { type: 'application/json' });
        const url = URL.createObjectURL(dataBlob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `todos-${new Date().toISOString().split('T')[0]}.json`;
        link.click();
        URL.revokeObjectURL(url);
        this.showToast('Tasks exported successfully', 'success');
    }

    importTodos(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const imported = JSON.parse(e.target.result);
                
                if (!Array.isArray(imported)) {
                    throw new Error('Invalid format: expected array of todos');
                }

                // Validate imported todos
                const validTodos = imported.filter(todo => 
                    todo.id && todo.text && todo.priority && todo.completed !== undefined
                );

                if (validTodos.length === 0) {
                    throw new Error('No valid todos found in file');
                }

                // Merge or replace
                const shouldMerge = confirm(
                    `Found ${validTodos.length} tasks.\nMerge with existing tasks? (Cancel = Replace)`
                );

                if (shouldMerge) {
                    // Merge: add imported todos that don't exist
                    const existingIds = new Set(this.todos.map(t => t.id));
                    const newTodos = validTodos.filter(t => !existingIds.has(t.id));
                    this.todos = [...this.todos, ...newTodos];
                } else {
                    // Replace
                    this.todos = validTodos;
                }

                this.saveToStorage();
                this.render();
                this.showToast(`Imported ${validTodos.length} tasks successfully`, 'success');
            } catch (error) {
                console.error('Import error:', error);
                this.showToast(`Import failed: ${error.message}`, 'error');
            }
        };
        reader.readAsText(file);
        event.target.value = ''; // Reset input
    }

    /**
     * Utilities
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `
            <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : type === 'warning' ? 'exclamation-triangle' : 'info-circle'}"></i>
            ${message}
        `;
        document.body.appendChild(toast);

        setTimeout(() => {
            toast.style.animation = 'slideInRight 0.3s ease reverse';
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new TodoApp();
});
