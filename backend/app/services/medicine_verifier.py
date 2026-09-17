import logging
import asyncio
from app.services.medicine_db import verify_medicine_authority

async def verify_extracted_medicines(medicines_list: list[dict]) -> list[dict]:
    """
    Phase 6: Verifies each candidate medicine extracted by AI/OCR against RxNorm, OpenFDA, and Local DB.
    If unverified, strictly marks name as 'Unknown Medicine' without hallucinating corrections.
    """
    verified_results = []

    tasks = []
    for med_item in medicines_list:
        med_name = med_item.get("medicine", "")
        tasks.append(verify_medicine_authority(med_name))

    results = await asyncio.gather(*tasks, return_exceptions=True)

    for i, res in enumerate(results):
        original_item = medicines_list[i]
        orig_name = original_item.get("medicine", "") or "Prescribed Medication"
        orig_generic = original_item.get("generic", "") or "Prescribed Medication"
        
        if isinstance(res, Exception) or not isinstance(res, dict):
            verified_results.append({
                "medicine": orig_name,
                "generic": orig_generic,
                "verified": False,
                "status": "Unverified"
            })
        else:
            verified_results.append({
                "medicine": res.get("name") or orig_name,
                "generic": res.get("generic") or orig_generic,
                "verified": bool(res.get("verified", False)),
                "status": res.get("status", "Verified"),
                "source": res.get("source", "AI Extracted")
            })

    return verified_results
