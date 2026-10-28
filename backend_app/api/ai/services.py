import os
import json
import math
import re
from fastapi import HTTPException
from openai import OpenAI

# Configure OpenRouter client if key exists
api_key = os.environ.get("OPENROUTER_API_KEY")
client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=api_key
) if api_key else None

def categorize_job_text(description: str):
    if not client:
        return {"category": "General Labor (Mock AI)"}
    try:
        prompt = f"Categorize this job description into a single short professional category name (e.g. Plumbing, Carpentry, Cleaning). Return ONLY the category name and nothing else. Description: '{description}'"
        response = client.chat.completions.create(
            model="google/gemma-4-31b-it:free",
            messages=[{"role": "user", "content": prompt}],
        )
        return {"category": response.choices[0].message.content.strip()}
    except Exception as e:
        print(f"AI Categorization Failed: {e}. Falling back to mock data.")
        return {"category": "Plumbing (Mock AI Fallback)"}

def suggest_fair_wage(skills: list, location: str):
    if not client:
        return {"suggested_wage": "Rs. 800 - Rs. 1200 (Mock AI)"}
    try:
        prompt = f"Suggest a fair daily wage range in INR for a worker in '{location}' with these skills: {skills}. Return ONLY the range, e.g., 'Rs. 800-Rs. 1200'. Do not include any other text or explanation."
        response = client.chat.completions.create(
            model="google/gemma-4-31b-it:free",
            messages=[{"role": "user", "content": prompt}],
        )
        return {"suggested_wage": response.choices[0].message.content.strip()}
    except Exception as e:
        print(f"AI Wage Suggestion Failed: {e}. Falling back to mock data.")
        return {"suggested_wage": "Rs. 1200 - Rs. 1600 (Mock AI Fallback)"}

def haversine(lat1, lon1, lat2, lon2):
    R = 6371.0 # Earth radius in kilometers
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)
    a = math.sin(dLat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dLon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def score_workers(job_desc: str, job_lat: float, job_lon: float, workers: list):
    def fallback_scoring(workers_list):
        job_desc_lower = job_desc.lower()
        scored = []
        for w in workers_list:
            score = 60
            skills = w.get('skillsList', [])
            
            matches = 0
            for skill in skills:
                if skill.lower() in job_desc_lower:
                    matches += 1
            score += matches * 15
            score += w.get('averageRating', 0.0) * 2
            
            dist = haversine(job_lat, job_lon, w.get('latitude', 0.0), w.get('longitude', 0.0))
            penalty = min(dist, 30.0)
            score -= penalty
            
            if score > 99: score = 99
            if score < 0: score = 0
                
            scored.append({
                "uid": w['uid'],
                "match_score": int(score),
                "distance_km": round(dist, 2)
            })
        return scored

    if not client:
        return fallback_scoring(workers)
        
    try:
        prompt = f"Extract a concise JSON array of required skills/keywords from this job description: '{job_desc}'. Return ONLY a valid JSON array of strings, like [\"plumbing\", \"wiring\"] and absolutely no other text or explanation."
        response = client.chat.completions.create(
            model="google/gemma-4-31b-it:free",
            messages=[{"role": "user", "content": prompt}],
        )
        content = response.choices[0].message.content.strip()
        
        # Clean up possible markdown code blocks around JSON
        if "```json" in content:
            content = content.split("```json")[1].split("```")[0].strip()
        elif "```" in content:
            content = content.split("```")[1].split("```")[0].strip()
            
        # Try to find array brackets if the model still included text
        match = re.search(r'\[.*\]', content, re.DOTALL)
        if match:
            content = match.group(0)
            
        required_skills = json.loads(content)
        if not isinstance(required_skills, list):
            required_skills = []
            
        required_skills = [str(s).lower() for s in required_skills]
        
        scored = []
        for w in workers:
            score = 50
            skills = [str(s).lower() for s in w.get('skillsList', [])]
            
            matches = 0
            for skill in skills:
                for req in required_skills:
                    if req in skill or skill in req:
                        matches += 1
                        break
            
            score += matches * 15
            score += w.get('averageRating', 0.0) * 2
            
            dist = haversine(job_lat, job_lon, w.get('latitude', 0.0), w.get('longitude', 0.0))
            penalty = min(dist, 30.0)
            score -= penalty
            
            if score > 99: score = 99
            if score < 0: score = 0
            
            scored.append({
                "uid": w['uid'],
                "match_score": int(score),
                "distance_km": round(dist, 2)
            })
        return scored
    except Exception as e:
        print(f"AI Match Scoring Failed: {e}. Falling back to keyword search.")
        return fallback_scoring(workers)
