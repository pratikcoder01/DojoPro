import { Router, Response, NextFunction } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.middleware';
import { AuthenticatedRequest } from '../types';

const router = Router();

// Zod validation schemas
const availabilitySchema = z.object({
  slots: z.array(z.string().datetime()),
});

const studentNotesSchema = z.object({
  student_id: z.string(),
  note: z.string(),
});

// In-memory mock storage for coach dashboard data (Sensei Priya Rao)
let mockEarnings = {
  thisWeek: 12400,
  thisMonth: 48200,
  totalStudents: 34,
  nextPayoutAmount: 18500,
  nextPayoutDate: '2026-06-15',
  chartData: [1500, 2400, 1800, 3200, 2900, 4100, 3800, 5200], // Last 8 weeks
};

let mockUpcomingSessions = [
  {
    id: 'sess_1',
    athleteName: 'Arjun Mehta',
    beltLevel: 'brown',
    sessionType: 'in-person',
    time: new Date(Date.now() + 15 * 60 * 1000).toISOString(), // Today in 15 minutes (starts within 30 min)
    amount: 800,
  },
  {
    id: 'sess_2',
    athleteName: 'Rohan Sharma',
    beltLevel: 'black',
    sessionType: 'online',
    time: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
    amount: 800,
  },
  {
    id: 'sess_3',
    athleteName: 'Pooja Patel',
    beltLevel: 'green',
    sessionType: 'online',
    time: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(), // Day after tomorrow
    amount: 800,
  },
  {
    id: 'sess_4',
    athleteName: 'Aisha Khan',
    beltLevel: 'blue',
    sessionType: 'in-person',
    time: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
    amount: 800,
  },
  {
    id: 'sess_5',
    athleteName: 'Sameer Joshi',
    beltLevel: 'yellow',
    sessionType: 'in-person',
    time: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000).toISOString(),
    amount: 800,
  },
];

let mockStudents = [
  {
    id: 'stud_1',
    name: 'Arjun Mehta',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    beltLevel: 'brown',
    lastSessionDate: '2026-06-08',
    progressStatus: 'On Track',
    attendanceLog: [
      'Shotokan Karate Kata Class - 2026-06-08',
      'Kumite Sparring Practice - 2026-06-05',
      'Strength & Conditioning - 2026-06-03',
    ],
    coachNotes: 'Excellent hip drive on kicks. Needs to keep guard higher during combinations.',
    beltProgression: [
      { level: 'white', earnedDate: '2024-01-15' },
      { level: 'yellow', earnedDate: '2024-06-10' },
      { level: 'green', earnedDate: '2024-12-05' },
      { level: 'blue', earnedDate: '2025-05-20' },
      { level: 'brown', earnedDate: '2025-11-10' },
    ],
    nextMilestones: ['Refine Bassai Dai kata forms', 'Increase sparring stamina'],
  },
  {
    id: 'stud_2',
    name: 'Rohan Sharma',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    beltLevel: 'black',
    lastSessionDate: '2026-06-03',
    progressStatus: 'Advanced',
    attendanceLog: [
      'Advanced Kumite Fighting - 2026-06-03',
      'Tactical Combat Drills - 2026-05-27',
    ],
    coachNotes: 'Sharp reflexes. Focus on tournament rules limits and clinch exits.',
    beltProgression: [
      { level: 'white', earnedDate: '2023-03-10' },
      { level: 'yellow', earnedDate: '2023-09-12' },
      { level: 'green', earnedDate: '2024-03-15' },
      { level: 'blue', earnedDate: '2024-09-18' },
      { level: 'brown', earnedDate: '2025-03-22' },
      { level: 'black', earnedDate: '2026-01-10' },
    ],
    nextMilestones: ['Preparation for National Karate Division Open'],
  },
  {
    id: 'stud_3',
    name: 'Pooja Patel',
    avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    beltLevel: 'green',
    lastSessionDate: '2026-05-20',
    progressStatus: 'Needs Focus',
    attendanceLog: [
      'Intro to Leverage & Throws - 2026-05-20',
    ],
    coachNotes: 'Needs more consistency in attendance. Leverage techniques are promising.',
    beltProgression: [
      { level: 'white', earnedDate: '2025-02-10' },
      { level: 'yellow', earnedDate: '2025-08-15' },
      { level: 'green', earnedDate: '2026-02-20' },
    ],
    nextMilestones: ['Attend 3 consecutive weekly sparring sessions', 'Green belt requirements revision'],
  },
];

let mockAvailabilitySlots: string[] = [];

// Initialize some mock availability times for the week
const initAvailability = () => {
  const now = new Date();
  const baseDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  mockAvailabilitySlots = [
    new Date(baseDate.getTime() + 3600000 * 10).toISOString(), // Today 10am
    new Date(baseDate.getTime() + 3600000 * 34).toISOString(), // Tomorrow 10am
    new Date(baseDate.getTime() + 3600000 * 58).toISOString(), // Day after 10am
  ];
};
initAvailability();

// @route   GET /api/v1/coaches/:id/dashboard
// @desc    Retrieve coach dashboard metrics, upcoming bookings, and students
// @access  Authenticated
router.get('/:id/dashboard', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    res.status(200).json({
      earnings: mockEarnings,
      upcomingSessions: mockUpcomingSessions,
      studentRoster: mockStudents.map(s => ({
        id: s.id,
        name: s.name,
        avatar: s.avatar,
        beltLevel: s.beltLevel,
        lastSessionDate: s.lastSessionDate,
        progressStatus: s.progressStatus,
      })),
      availabilitySlots: mockAvailabilitySlots,
    });
  } catch (err) {
    next(err);
  }
});

// @route   GET /api/v1/coaches/:id/students
// @desc    Retrieve list of all students with full profile details
// @access  Authenticated
router.get('/:id/students', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    res.status(200).json({
      students: mockStudents,
    });
  } catch (err) {
    next(err);
  }
});

// @route   PUT /api/v1/coaches/:id/availability
// @desc    Set/Update coach availability slots
// @access  Authenticated
router.put('/:id/availability', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validation = availabilitySchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid availability slots.',
          details: validation.error.format(),
        },
      });
    }

    mockAvailabilitySlots = validation.data.slots;
    res.status(200).json({
      message: 'Availability updated successfully.',
      slots: mockAvailabilitySlots,
    });
  } catch (err) {
    next(err);
  }
});

// @route   POST /api/v1/coaches/:id/student-notes
// @desc    Add/Update coach notes for a student
// @access  Authenticated
router.post('/:id/student-notes', requireAuth, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validation = studentNotesSchema.safeParse(req.body);
    if (!validation.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid parameters for student notes.',
          details: validation.error.format(),
        },
      });
    }

    const { student_id, note } = validation.data;
    const student = mockStudents.find(s => s.id === student_id);

    if (!student) {
      return res.status(404).json({
        error: {
          code: 'STUDENT_NOT_FOUND',
          message: 'The requested student was not found in the roster.',
        },
      });
    }

    student.coachNotes = note;

    res.status(200).json({
      message: 'Student notes updated successfully.',
      student_id,
      notes: note,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
