import os
import json
from dotenv import load_dotenv

# Load the env variables
load_dotenv()

# We can import directly from services to test the function logic
from api.ai.services import score_workers, categorize_job_text, suggest_fair_wage

print("Testing OpenRouter AI Integration...\n")

print("1. Testing Categorization...")
cat = categorize_job_text("I need someone to install a new toilet and fix a leaky pipe in the bathroom.")
print("Result:", cat)

print("\n2. Testing Wage Suggestion...")
wage = suggest_fair_wage(["Plumbing", "Pipe Fitting"], "Lahore")
print("Result:", wage)

print("\n3. Testing Smart Matching...")
job_desc = "Need a skilled plumber to fix a broken pipe and install a new sink."
workers = [
    {
        "uid": "worker1",
        "skillsList": ["plumbing", "painting", "pipe fitting"],
        "averageRating": 4.5,
        "latitude": 31.5204,
        "longitude": 74.3587
    },
    {
        "uid": "worker2",
        "skillsList": ["electrician", "wiring"],
        "averageRating": 5.0,
        "latitude": 31.5204, # Same location
        "longitude": 74.3587
    },
    {
        "uid": "worker3",
        "skillsList": ["plumbing"],
        "averageRating": 2.0,
        "latitude": 31.5204,
        "longitude": 74.3587
    }
]

# Using same job location to test pure skill/rating scores
scores = score_workers(job_desc, 31.5204, 74.3587, workers)

print("\nJob Description:", job_desc)
print("\nWorkers Score Results:")
for s in scores:
    print(s)
