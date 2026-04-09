---
name: healthcare:phi-compliance
description: PHI handling — minimize exposure, never log PHI, encrypt at rest and transit, audit trail
trigger: |
  - Handling patient data, names, dates, diagnoses, or any healthcare identifiers
  - Logging or debugging code that processes healthcare records
  - Storing healthcare data in the database
  - Sending healthcare data to external services or APIs
skip_when: |
  - Completely de-identified or synthetic data with no link to real patients
---

# PHI Compliance (HIPAA-aligned)

## The 18 HIPAA Identifiers

These fields make data PHI and require protection:

1. Names, 2. Geographic subdivisions smaller than state, 3. Dates (except year) related to individual
4. Phone numbers, 5. Fax numbers, 6. Email addresses, 7. SSNs, 8. Medical record numbers
9. Health plan beneficiary numbers, 10. Account numbers, 11. Certificate/license numbers
12. VINs, 13. Device identifiers, 14. Web URLs, 15. IP addresses, 16. Biometric identifiers
17. Full-face photographs, 18. Any other unique identifying number or code

**When in doubt, treat it as PHI.**

## Minimize PHI Exposure

Access the minimum necessary data for the task. Request only the fields you need.

```typescript
// BAD — fetches full record including all PHI
const patient = await db.from('patients').select('*').eq('id', patientId).single();

// GOOD — only the fields needed for this operation
const { data: patient } = await db
  .from('patients')
  .select('id, appointment_date, provider_id')  // no name, DOB, etc.
  .eq('id', patientId)
  .single();
```

## Never Log PHI

```typescript
// BAD — PHI in logs
console.log('Processing patient:', patient.name, patient.dob, patient.diagnosis);
console.error('Failed to update record:', JSON.stringify(patientRecord));

// GOOD — log identifiers only (non-PHI)
console.log('Processing patient record:', patient.id, 'for provider:', patient.provider_id);
console.error('Failed to update record id:', recordId, 'error:', error.message);

// For debugging PHI issues, use structured audit logging (not console)
await auditLog.write({
  action: 'record_access',
  record_id: patient.id,
  user_id: currentUser.id,
  timestamp: new Date().toISOString(),
  // No PHI values
});
```

## Encrypt at Rest and Transit

```sql
-- Database: enable pgcrypto for sensitive columns
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt sensitive text at rest
UPDATE patients
SET ssn_encrypted = pgp_sym_encrypt(ssn_plaintext, current_setting('app.encryption_key'))
WHERE ssn_plaintext IS NOT NULL;

-- Decrypt only in server-side code, never client-side
SELECT pgp_sym_decrypt(ssn_encrypted::bytea, current_setting('app.encryption_key')) AS ssn
FROM patients WHERE id = $1;
```

```typescript
// HTTPS enforced — reject HTTP in production
if (process.env.NODE_ENV === 'production' && req.headers['x-forwarded-proto'] !== 'https') {
  return res.redirect(301, `https://${req.headers.host}${req.url}`);
}
```

## Audit Trail

Every access to PHI must be logged with: who, what, when, why.

```typescript
interface PhiAuditEntry {
  id: string;
  user_id: string;
  patient_id: string;         // record identifier (not PHI itself)
  action: 'view' | 'create' | 'update' | 'delete' | 'export';
  resource_type: string;      // "clinical_note", "prescription", etc.
  resource_id: string;
  ip_address: string;
  user_agent: string;
  timestamp: string;          // ISO 8601
  reason: string | null;      // optional break-glass reason
}

async function logPhiAccess(entry: Omit<PhiAuditEntry, 'id' | 'timestamp'>) {
  await db.from('phi_audit_log').insert({
    ...entry,
    timestamp: new Date().toISOString(),
  });
}
```

## Third-Party Services

```typescript
// Before sending any data to external LLM APIs or services:
// 1. De-identify: replace PHI with tokens
// 2. Contractual: verify BAA (Business Associate Agreement) in place
// 3. Minimal: send only what is required

function deidentify(text: string, patientId: string): string {
  // Replace patient-specific identifiers with generic tokens
  return text
    .replace(/\b(patient|pt)\s+\w+/gi, 'PATIENT')
    .replace(/\b\d{3}-\d{2}-\d{4}\b/g, '[SSN]')  // SSN pattern
    .replace(/\b\d{2}\/\d{2}\/\d{4}\b/g, '[DATE]');
}
```

## Checklist

- [ ] Only HIPAA minimum-necessary fields selected in queries
- [ ] No PHI values in `console.log`, `console.error`, or application logs
- [ ] Sensitive columns encrypted at rest with pgcrypto or app-layer encryption
- [ ] All connections use TLS (HTTPS enforced in production)
- [ ] Every PHI access logged to `phi_audit_log` (who, what, when)
- [ ] PHI de-identified before sending to external LLM APIs
- [ ] BAA in place with all vendors that process PHI
- [ ] PHI never stored in localStorage, sessionStorage, or URL params
