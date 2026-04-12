# rpms-tests

Pytest test suite for the RPMS IRIS Community Edition RPC broker image built by
[CivicActions/docker-vista](https://github.com/CivicActions/docker-vista).

Tests exercise the XWB RPC Broker (port 9100) and BMX Broker (port 9101) using the
[vista-clients](https://github.com/CivicActions/vista-clients) Python library.

## Prerequisites

- Docker (to run the RPMS container)
- Python 3.10+ and [uv](https://docs.astral.sh/uv/)
- The RPMS IRIS CE image with seeded test users and patients (see below)

## Quick start

```bash
# 1. Start the RPMS container (XWB on 9100, BMX on 9101)
docker run -d -p 9100:9100 -p 9101:9101 -p 52773:52773 --name rpms-test \
  ghcr.io/civicactions/rpms-iris:civicactions

# 2. Wait for the XWB broker to become ready (~30-60s)
until nc -z localhost 9100 2>/dev/null; do sleep 1; done

# 3. Install dependencies and run tests
uv sync
uv run pytest tests/ -v
```

## Configuration

| Environment variable | Default       | Description                    |
|---------------------|---------------|--------------------------------|
| `RPMS_HOST`         | `localhost`   | RPMS container hostname        |
| `RPMS_PORT`         | `9100`        | XWB RPC Broker port            |
| `RPMS_BMX_PORT`     | `9101`        | BMX Broker port                |
| `RPMS_ACCESS_CODE`  | `PROV123`     | VistA Access Code              |
| `RPMS_VERIFY_CODE`  | `PROV123!!`   | VistA Verify Code              |

## Seeded data

The container image includes pre-seeded test data:

### Users (3)

| DUZ | Name            | Access Code | Verify Code  |
|-----|-----------------|-------------|--------------|
| 1   | PROVIDER,TEST   | PROV123     | PROV123!!    |
| 2   | PROGRAMMER,SYSTEM | PROG123   | PROG123!!    |
| 3   | NURSE,TEST      | NURSE123    | NURSE123!!   |

### Patients (2)

| DFN | Name              | Gender | DOB        | Clinical Data |
|-----|-------------------|--------|------------|---------------|
| 100 | TESTPATIENT,ALICE | F      | 1980-01-15 | Visit, allergy (Penicillin), vitals (BP, Pulse, Temp), problem (Hypertension) |
| 101 | TESTPATIENT,BOB   | M      | 1975-06-20 | Visit, problem (Diabetes), no allergies/vitals |

## CI

The GitHub Actions workflow (`.github/workflows/test-rpms.yml`) automatically:

1. Pulls the RPMS IRIS CE image from GHCR
2. Starts a container with ports 9100 and 9101 exposed
3. Waits for the XWB broker to accept connections
4. Runs the full test suite

Trigger manually via `workflow_dispatch` to test a different image tag.

## Test structure

| File | Tests | Description |
|------|-------|-------------|
| `tests/conftest.py` | — | Shared fixtures — broker connection, auth, port config |
| `tests/test_connection.py` | 4 | XWB + BMX broker TCP connectivity |
| `tests/test_authentication.py` | 9 | Multi-user auth, DUZ mapping, verify code expiration |
| `tests/test_context.py` | 4 | XWB CREATE CONTEXT for RPMS option names |
| `tests/test_rpcs.py` | 5 | RPC invocation, response parsing, keepalive |
| `tests/test_rpms_discovery.py` | 7 | Site config, CIAV VUECENTRIC, BMXRPC contexts |
| `tests/test_patients.py` | 5 | ORWPT LIST ALL, demographics, DFN validation |
| `tests/test_clinical_data.py` | 7 | Allergies, vitals, problems, visits |
