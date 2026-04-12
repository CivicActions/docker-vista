"""Shared fixtures for RPMS RPC broker tests.

All tests in this suite require a running RPMS IRIS CE container
with the XWB broker listening on port 9100.
"""

from __future__ import annotations

import os
import socket
import time

import pytest

from vista_clients.rpc import VistABroker
from vista_clients.rpc.protocol import SessionState

# Mark every test in the suite as requiring a live RPMS instance
pytestmark = pytest.mark.rpms

# ---------------------------------------------------------------------------
# Environment-driven configuration
# ---------------------------------------------------------------------------

RPMS_HOST = os.environ.get("RPMS_HOST", "localhost")
RPMS_PORT = int(os.environ.get("RPMS_PORT", "9100"))
RPMS_BMX_PORT = int(os.environ.get("RPMS_BMX_PORT", "9101"))
RPMS_ACCESS_CODE = os.environ.get("RPMS_ACCESS_CODE", "PROV123")
RPMS_VERIFY_CODE = os.environ.get("RPMS_VERIFY_CODE", "PROV123!!")


def _wait_for_port(host: str, port: int, timeout: float = 60.0) -> None:
    """Block until *host:port* accepts a TCP connection."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            with socket.create_connection((host, port), timeout=2.0):
                return
        except OSError:
            time.sleep(1.0)
    raise RuntimeError(f"{host}:{port} not reachable after {timeout}s")


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(scope="session", autouse=True)
def _require_rpms_broker() -> None:
    """Fail fast if the RPMS broker is not reachable."""
    _wait_for_port(RPMS_HOST, RPMS_PORT)


@pytest.fixture()
def rpms_host() -> str:
    return RPMS_HOST


@pytest.fixture()
def rpms_port() -> int:
    return RPMS_PORT


@pytest.fixture()
def rpms_bmx_port() -> int:
    """BMX broker port (default 9101)."""
    return RPMS_BMX_PORT


@pytest.fixture()
def broker(rpms_host: str, rpms_port: int) -> VistABroker:
    """Return a connected (handshaked) broker; disconnect on teardown."""
    b = VistABroker(rpms_host, rpms_port)
    b.connect()
    yield b  # type: ignore[misc]
    b.disconnect()


@pytest.fixture()
def authenticated_broker(broker: VistABroker) -> VistABroker:
    """Return an authenticated broker (HANDSHAKED → AUTHENTICATED)."""
    broker.authenticate(access_code=RPMS_ACCESS_CODE, verify_code=RPMS_VERIFY_CODE)
    return broker


@pytest.fixture()
def context_broker(authenticated_broker: VistABroker) -> VistABroker:
    """Return a broker with the OR CPRS GUI CHART context set."""
    authenticated_broker.create_context("OR CPRS GUI CHART")
    assert authenticated_broker.state == SessionState.CONTEXT_SET
    return authenticated_broker
