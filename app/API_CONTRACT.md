# API Contract

## Report Ingestion

**Endpoint:** `POST /api/ingest/reports`

**Headers:**
- `Content-Type: application/json`
- `Content-Encoding: gzip` (optional, if payload > 1KB)
- `X-Device-ID: <UUID>`

**Request Body:**
```json
{
  "reports": [
    {
      "id": "uuid",
      "timestamp": "ISO8601",
      "signal_type": "string",
      "payload": {}
    }
  ]
}
```

**Responses:**
- `200 OK`: Reports processed successfully.
- `400 Bad Request`: Validation failed. Mark batch as failed/don't retry automatically without fixes.
- `5xx / Network Error`: WorkManager will retry.

## Batching Rules
- Max 100 reports per request.
- Aim for ~2KB packets.
- Gzip if payload > 1KB.
