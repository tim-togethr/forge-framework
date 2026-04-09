---
name: healthcare:llm-safety
description: LLM safety for healthcare — prompt guards, untrusted data markers, score validation, AI content labeling
trigger: |
  - Writing any prompt that calls an LLM
  - LLM outputs fed into clinical workflows or displayed to users
  - Scoring or evaluating content with an LLM
  - Displaying AI-generated content to clinicians or patients
skip_when: |
  - Internal dev tooling with no clinical impact and no user-facing output
---

# Healthcare LLM Safety

## Use Case Classification

Before writing any prompt, classify it:

| Class | Use Case | Temperature |
|-------|----------|-------------|
| A | RAG Extraction — pull facts from documents | 0.1 |
| B | Evaluation & Scoring — rate quality/risk | 0.1 |
| C | Chat / Assistant — conversational | 0.2–0.3 |
| D | Content Generation — summaries, drafts | 0.2 |

## Mandatory Prompt Guards

Every prompt MUST include all three clauses:

```python
SAFETY_GUARDS = """
NO FABRICATION: Only state information explicitly present in the provided context.
If information is absent, say "Not found in provided material" — never infer or assume.

UNCERTAINTY: When confidence is low or evidence is ambiguous, say so explicitly.
Use phrases like "The document suggests..." or "It is unclear whether...".

OUTPUT BOUNDARY: Respond only within the scope of the question asked.
Do not volunteer clinical advice, diagnoses, or treatment recommendations
beyond what is directly supported by the provided material.
"""

def build_prompt(system: str, user_content: str) -> list[dict]:
    return [
        {"role": "system", "content": system + "\n\n" + SAFETY_GUARDS},
        {"role": "user", "content": user_content},
    ]
```

## Untrusted Data Markers

Any data from external sources (vendor docs, patient input, scraped content) MUST be wrapped.

```python
def wrap_untrusted(source_type: str, content: str) -> str:
    return f"<<<UNTRUSTED_{source_type.upper()}_START>>>\n{content}\n<<<UNTRUSTED_{source_type.upper()}_END>>>"

# Usage
wrapped_note = wrap_untrusted("PATIENT_INPUT", raw_note_text)
wrapped_doc = wrap_untrusted("VENDOR_DOC", vendor_pdf_text)

prompt = f"""
Summarize the clinical findings from the following patient note.

{wrapped_note}

Only summarize information explicitly stated. Do not add clinical interpretation.
"""
```

## Score Validation and Clamping

**Never trust scores from LLMs directly.** Always validate and clamp server-side.

```python
import json

def extract_and_clamp_score(llm_response: str, field: str, min_val: float, max_val: float) -> float:
    try:
        data = json.loads(llm_response)
        raw = float(data[field])
    except (json.JSONDecodeError, KeyError, TypeError, ValueError):
        # Unparseable response — treat as minimum confidence
        return min_val

    # Clamp to valid range regardless of LLM output
    clamped = max(min_val, min(max_val, raw))

    # Not-found answers must have low confidence
    not_found_phrases = ["not found", "not present", "absent", "unclear"]
    answer = str(data.get("answer", "")).lower()
    if any(phrase in answer for phrase in not_found_phrases):
        clamped = min(clamped, 0.3)

    return clamped
```

## AI Content Labeling

All AI-generated content displayed to users must be labeled and flagged in the database.

```typescript
// UI: always show AI label with CpuChipIcon
import { CpuChipIcon } from '@heroicons/react/24/outline';

function AiGeneratedBadge() {
  return (
    <span className="flex items-center gap-1 text-xs text-amber-600">
      <CpuChipIcon className="h-3 w-3" />
      AI-generated — verify before use
    </span>
  );
}

// Database: always store provenance
interface ClinicalNote {
  content: string;
  ai_generated: boolean;      // true for LLM output
  ai_model: string | null;    // "claude-3-5-sonnet-20241022"
  ai_prompt_version: string | null;
  reviewed_by: string | null; // clinician who verified
  reviewed_at: Date | null;
}
```

## Checklist

- [ ] Use case classified (A/B/C/D) and temperature set accordingly
- [ ] All prompts include: No Fabrication, Uncertainty, Output Boundary clauses
- [ ] External/untrusted data wrapped with `<<<UNTRUSTED_*_START/END>>>` markers
- [ ] LLM scores never used raw — always validated and clamped server-side
- [ ] Not-found answers clamped to ≤ 0.3 confidence
- [ ] AI-generated content labeled in UI (CpuChipIcon)
- [ ] `ai_generated: true` stored in database with model version
- [ ] No LLM calls made client-side with exposed API keys
