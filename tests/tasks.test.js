const request = require('supertest');
const app = require('../src/app');

// 'describe' groups related tests together
describe('Task API', () => {

  // ── Health Check ──
  describe('GET /health', () => {
    it('should return status OK', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('OK');
    });
  });

  // ── GET all tasks ──
  describe('GET /tasks', () => {
    it('should return an empty array initially', async () => {
      const res = await request(app).get('/tasks');
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  // ── POST create task ──
  describe('POST /tasks', () => {
    it('should create a new task', async () => {
      const res = await request(app)
        .post('/tasks')
        .send({ title: 'Buy groceries', description: 'Milk and eggs' });

      expect(res.statusCode).toBe(201);
      expect(res.body.title).toBe('Buy groceries');
      expect(res.body.id).toBeDefined();       // ID was generated
      expect(res.body.completed).toBe(false);  // default value
    });

    it('should return 400 if title is missing', async () => {
      const res = await request(app)
        .post('/tasks')
        .send({ description: 'No title here' });

      expect(res.statusCode).toBe(400);
      expect(res.body.error).toBe('Title is required');
    });
  });

  // ── DELETE task ──
  describe('DELETE /tasks/:id', () => {
    it('should delete an existing task', async () => {
      // First create a task
      const created = await request(app)
        .post('/tasks')
        .send({ title: 'Task to delete' });

      const id = created.body.id;

      // Then delete it
      const res = await request(app).delete(`/tasks/${id}`);
      expect(res.statusCode).toBe(200);
    });

    it('should return 404 for non-existent task', async () => {
      const res = await request(app).delete('/tasks/fake-id-999');
      expect(res.statusCode).toBe(404);
    });
  });

});
