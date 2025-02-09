const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();
const authenticateToken = require('./middleware/authMiddleware'); // Import middleware
 const app = express();
const port = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
// Middleware
app.use(cors());
app.use(bodyParser.json());

// MySQL connection
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});
// Connect to MySQL
db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
  } else {
    console.log('Connected to MySQL database');
  }
});

app.post('/api/assignment', (req, res) => {
    const { title, date, startTime, stopTime } = req.body;
  
    // Validate title
    if (!title || typeof title !== 'string') {
      return res.status(400).json({ error: 'Title is required and must be a string' });
    }
  
    const query = 'INSERT INTO assignments (title, date, start_time, stop_time) VALUES (?, ?, ?, ?)';
    db.query(query, [title, date, startTime, stopTime], (err, result) => {
      if (err) {
        console.error('Error creating assignment:', err);
        res.status(500).json({ error: 'Something went wrong' });
      } else {
        res.status(200).json({ id: result.insertId, title, date, startTime, stopTime });
      }
    });
  });
// Get all assignments
app.get('/api/assignment', (req, res) => {
  const query = 'SELECT * FROM assignments';
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching assignments:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/api/assignments', (req, res) => {
  const query = 'SELECT * FROM assignment';
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching assignments:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});

// Create a new task for an assignment
app.post('/api/tasks', (req, res) => {
  const { assignmentId, taskTitle, taskTime } = req.body;
  const query = 'INSERT INTO tasks (assignment_id, task_title, task_time) VALUES (?, ?, ?)';
  db.query(query, [assignmentId, taskTitle, taskTime], (err, result) => {
    if (err) {
      console.error('Error creating task:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(201).json({ id: result.insertId, assignmentId, taskTitle, taskTime });
    }
  });
});

// Get tasks for a specific assignment
app.get('/api/tasks/:assignmentId', (req, res) => {
  const { assignmentId } = req.params;
  const query = 'SELECT * FROM tasks WHERE assignment_id = ?';
  db.query(query, [assignmentId], (err, results) => {
    if (err) {
      console.error('Error fetching tasks:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
 app.get('/api/student', (req, res) => {
  const query = 'SELECT *FROM student';
  
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching student details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
// Get all faculty details
app.get('/api/faculty', (req, res) => {
  const query = 'SELECT * FROM faculty';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching faculty details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/api/student', (req, res) => {
  const query = 'SELECT * FROM students';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching faculty details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/api/questions', (req, res) => {
  const query = 'SELECT * FROM questions';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching   details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/api/rank', (req, res) => {
  const query = 'SELECT * FROM rank';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching   details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.post('/api/rank', (req, res) => {
  const { assignment_id, faculty_id, task_number, rank_1, rank_2, rank_3, rank_4, rank_5 } = req.body;

  if (!assignment_id || !faculty_id || !task_number || !rank_1 || !rank_2 || !rank_3 || !rank_4 || !rank_5) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  const query = `
  INSERT INTO \`rank\` (assignment_id, faculty_id, task_number, rank_1, rank_2, rank_3, rank_4, rank_5, created_at) 
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
`;


  db.query(query, [assignment_id, faculty_id, task_number, rank_1, rank_2, rank_3, rank_4, rank_5], (err, result) => {
    if (err) {
      console.error('Error inserting ranking:', err);
      return res.status(500).json({ error: 'Something went wrong' });
    }
    res.status(201).json({ message: 'Ranking added successfully', id: result.insertId });
  });
});

app.get('/api/students', (req, res) => {
  const query = 'SELECT id, name FROM students'; // Assuming `students` table has columns `id` and `name`

  connection.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching student names:', err);
      return res.status(500).json({ error: 'Failed to retrieve students' });
    }
    res.status(200).json(results);
  });
});
 

// app.get('/api/result', (req, res) => {
//   const query = 'SELECT *from result'; // Assuming `students` table has columns `id` and `name`

//   connection.query(query, (err, results) => {
//     if (err) {
//       console.error('Error fetching  ranking :', err);
//       return res.status(500).json({ error: 'Failed to retrieve ' });
//     }
//     res.status(200).json(results);
//   });
// });
// Start the server
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
// Get all students
app.get('/api/students', (req, res) => {
  const query = 'SELECT * FROM student';
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching student details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
// Get all assignments data
app.get('/api/assignment', (req, res) => {
  const { title } = req.query; // Get the title from query parameter

  let query = 'SELECT * FROM assignments';
  if (title) {
    query += ' WHERE title = ?'; // Add a condition if title is provided
  }

  db.query(query, [title], (err, results) => { // Use `db.query` instead of `connection.query`
    if (err) {
      console.error('Error fetching data:', err);
      return res.status(500).json({ error: 'Failed to retrieve assignments' });
    }
    res.status(200).json(results); // Send the data back as a JSON response
  });
});

// Handle creating an assignment
app.post('/api/assignments', (req, res) => {
  const { title, date, start_time, stop_time, explanation, number_of_students, numberoftasks, numberofranks, task_details, total_time } = req.body;

  const query = `
    INSERT INTO assignment (
      title, date, start_time, stop_time, explanation, number_of_students, numberoftasks, numberofranks, task_details, total_time
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  db.query( // Use `db.query` instead of `connection.query`
    query,
    [title, date, start_time, stop_time, explanation, number_of_students, numberoftasks, numberofranks, JSON.stringify(task_details), total_time],
    (err, results) => {
      if (err) {
        console.error('Error inserting data:', err);
        return res.status(500).json({ error: 'Failed to save assignment' });
      }
      res.status(200).json({ message: 'Assignment saved successfully', id: results.insertId });
    }
  );
});
app.get('/api/namelist', (req, res) => {
  const query = 'SELECT * FROM namelist';
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching assignments:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
const getPoints = (rank) => {
  switch (rank) {
    case 1:
      return 4;
    case 2:
      return 3;
    case 3:
      return 2;
    case 4:
      return 1;
    default:
      return 0;
  }
};

// Fetch Ranks and Calculate Results
app.get("/api/result", async (req, res) => {
  try {
    const response = await axios.get("http://192.168.205.45:5000/api/rank");
    const rankingData = response.data; // Assuming this returns an array of ranks

    let studentPoints = {};

    rankingData.forEach(({ ranked_student_id, rank_given }) => {
      if (!studentPoints[ranked_student_id]) {
        studentPoints[ranked_student_id] = [];
      }
      studentPoints[ranked_student_id].push(getPoints(rank_given));
    });

    let results = [];
    for (const student_id in studentPoints) {
      const totalPoints = studentPoints[student_id].reduce((a, b) => a + b, 0);
      const averagePoints = totalPoints / studentPoints[student_id].length;
      const result_status = averagePoints >= 2 ? "PASS" : "FAIL";

      results.push({ student_id, totalPoints, averagePoints, result_status });

      // Store results in MySQL
      const sql = "INSERT INTO result (student_id, total_points, average_points, result_status) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE total_points=?, average_points=?, result_status=?";
      db.query(sql, [student_id, totalPoints, averagePoints, result_status, totalPoints, averagePoints, result_status], (err) => {
        if (err) console.error("Error inserting results:", err);
      });
    }

    res.json({ success: true, results });
  } catch (error) {
    console.error("Error fetching ranking data:", error);
    res.status(500).json({ success: false, error: "Failed to fetch rankings" });
  }
});


// 📌 GET all student results
app.get("/api/student_results", (req, res) => {
  const sql = "SELECT * FROM student_results";
  db.query(sql, (err, results) => {
    if (err) {
      console.error("Error fetching student results:", err);
      return res.status(500).json({ success: false, error: "Database error" });
    }
    res.json({ success: true, data: results });
  });
});

// 📌 POST new student result
app.post("/api/student_results", (req, res) => {
  const { faculty_id, total_points, average_points, result_status } = req.body;

  if (!faculty_id || total_points === undefined || average_points === undefined || !result_status) {
    return res.status(400).json({ success: false, error: "Missing required fields" });
  }

  const sql = `INSERT INTO student_results (faculty_id, total_points, average_points, result_status) VALUES (?, ?, ?, ?)`;
  db.query(sql, [faculty_id, total_points, average_points, result_status], (err, result) => {
    if (err) {
      console.error("Error inserting student result:", err);
      return res.status(500).json({ success: false, error: "Database insert error" });
    }
    res.json({ success: true, message: "Student result added", id: result.insertId });
  });
});
app.post("/api/allocate-question", (req, res) => {
  const { student_id, task_id, question_id } = req.body;
  const sql = `INSERT INTO AllocatedQuestions (student_id, task_id, question_id) VALUES (?, ?, ?)`;

  db.query(sql, [student_id, task_id, question_id], (err, result) => {
      if (err) {
          console.error("Error allocating question: " + err.message);
          res.status(500).json({ error: "Database error" });
      } else {
          res.json({ message: "Question allocated successfully", id: result.insertId });
      }
  });
});

// API to get allocated questions for a student
app.get("/api/allocated-questions/:student_id", (req, res) => {
  const { student_id } = req.params;
  const sql = `
      SELECT aq.id, aq.allocated_at, q.question 
      FROM AllocatedQuestions aq
      JOIN Questions q ON aq.question_id = q.id
      WHERE aq.student_id = ?
  `;

  db.query(sql, [student_id], (err, results) => {
      if (err) {
          console.error("Error fetching allocated questions: " + err.message);
          res.status(500).json({ error: "Database error" });
      } else {
          res.json(results);
      }
  });
});