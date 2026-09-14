# AI Recruiter 🎙️🤖

A full-stack AI-powered interview preparation platform that simulates real recruiter interactions through voice-based interviews. The system analyzes resumes, generates personalized interview questions, conducts voice interviews, evaluates responses, and provides detailed performance reports.

---

## ✨ Features

### 🔐 Authentication....

* Firebase Authentication
* Secure Login & Signup
* Persistent User Sessions

### 📄 Resume Intelligence

* Upload Resume (PDF)
* Resume Text Extraction
* AI-Powered Resume Analysis
* Skill Extraction
* Project Identification
* Experience & Education Parsing
* Strengths & Weak Areas Detection

### 🎯 Interview Modes

* **Resume-Based Interview**
* **Skill-Based Interview**
* **Hybrid Interview**

### 🎙️ Voice AI Recruiter

* AI Recruiter asks questions using Text-to-Speech (TTS)
* Candidate responds using Speech-to-Text (STT)
* Real-time Transcript Generation
* Auto Silence Detection
* Conversational Interview Experience

### 🤖 Dynamic Question Generation

Questions are generated based on:

* Resume Content
* Selected Skills
* Target Role
* Experience Level
* Difficulty Level

### 📊 AI Evaluation

* Technical Accuracy Score
* Communication Score
* Confidence Score
* Problem-Solving Score
* Overall Performance Analysis

### 📈 Analytics Dashboard

* Total Interviews
* Average Score
* Best Score
* Interview History
* Performance Trends

---

## 🏗️ Tech Stack

### Frontend

* Flutter
* Provider
* Go Router
* Material 3

### Backend

* FastAPI
* Python

### Database

* Firebase Firestore

### Authentication

* Firebase Authentication

### AI

* Google Gemini API

### Voice Processing

* Flutter TTS
* Speech To Text

### Resume Processing

* PyPDF2

---

## 📂 Project Structure

```bash
AI_RECRUITER/
│
├── lib/
│   ├── core/
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── interview/
│   │   ├── history/
│   │   └── profile/
│   ├── shared/
│   └── main.dart
│
├── backend/
│   ├── routes/
│   ├── services/
│   ├── uploads/
│   ├── main.py
│   └── requirements.txt
│
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Clone Repository

```bash
git clone https://github.com/yourusername/ai-recruiter.git
cd ai-recruiter
```

### Flutter Setup

```bash
flutter pub get
flutter run
```

### Backend Setup

```bash
cd backend

python -m venv .venv

# Windows
.venv\Scripts\activate

# Linux/Mac
source .venv/bin/activate

pip install -r requirements.txt

uvicorn main:app --reload
```

Backend runs at:

```text
http://127.0.0.1:8000
```

---

## 🔑 Environment Variables

Create a `.env` file inside the backend folder:

```env
GEMINI_API_KEY=your_gemini_api_key
```

---

## 🔥 Firebase Setup

1. Create a Firebase Project.
2. Enable Authentication.
3. Enable Firestore Database.
4. Download `google-services.json`.
5. Place it inside:

```text
android/app/google-services.json
```

---

## 📱 Application Flow

```text
Login
   ↓
Upload Resume
   ↓
Resume Analysis
   ↓
Select Interview Mode
   ↓
Start Voice Interview
   ↓
Answer Questions
   ↓
AI Evaluation
   ↓
Interview Report
   ↓
Analytics Dashboard
```

---

## 📊 Firestore Structure

```text
users
 └── {uid}
      ├── profile
      ├── resumeProfile
      └── interviews
           └── {interviewId}
```

---

## 🎯 Key Highlights

* Full-Stack Flutter + FastAPI Application
* Voice-Based AI Interview Simulation
* Resume-Aware Question Generation
* Real-Time Speech Processing
* AI-Powered Evaluation System
* Firebase Integration
* Modular Clean Architecture
* Production-Oriented Design

---

## 🔮 Future Enhancements

* Emotion Detection
* Eye Contact Analysis
* Company-Specific Interview Preparation
* Multi-Language Interviews
* Coding Interview Mode
* AI Career Guidance

---

## 👨‍💻 Author

**Kartik Baliyan**

* LinkedIn: https://linkedin.com/in/kartikbaliyan
* GitHub: https://github.com/kartik23-2

---

## 📄 License

This project is licensed under the MIT License.
