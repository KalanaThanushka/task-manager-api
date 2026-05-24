const express = require('express');
const { v4: uuidv4 } = require('uuid');

const app = express();

// Middleware: tells Express to accept JSON in request body
app.use(express.json());

// In-memory "database" — just an array for now
// In a real app this would be a real database like PostgreSQL
let tasks = [];

// ─── ROUTES ───────────────────────────────────────────

// Health Check — CI/CD pipelines use this to verify the app is alive
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString(), version: '1.1.0' });
});

// GET all tasks
app.get('/tasks', (req, res) => {
  res.status(200).json(tasks);
});

// GET single task by ID
app.get('/tasks/:id', (req, res) => {
  const task = tasks.find(t => t.id === req.params.id);
  if (!task) return res.status(404).json({ error: 'Task not found' });
  res.status(200).json(task);
});

// POST — create a new task
app.post('/tasks', (req, res) => {
  const { title, description } = req.body;

  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }

  const newTask = {
    id: uuidv4(),       // generates a unique ID like "a3f9c2d1-..."
    title,
    description: description || '',
    completed: false,
    createdAt: new Date().toISOString()
  };

  tasks.push(newTask);
  res.status(201).json(newTask);
});

// PUT — update a task
app.put('/tasks/:id', (req, res) => {
  const index = tasks.findIndex(t => t.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Task not found' });

  tasks[index] = { ...tasks[index], ...req.body };
  res.status(200).json(tasks[index]);
});

// DELETE — remove a task
app.delete('/tasks/:id', (req, res) => {
  const index = tasks.findIndex(t => t.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Task not found' });

  tasks.splice(index, 1);
  res.status(200).json({ message: 'Task deleted' });
});

module.exports = app;
