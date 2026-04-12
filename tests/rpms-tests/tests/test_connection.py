"""Connection and handshake tests for the RPMS XWB broker."""

import socket

import pytest

from vista_clients.rpc import BrokerConnectionError, VistABroker
from vista_clients.rpc.protocol import SessionState


class TestConnection:
    """TCP connect / disconnect against the RPMS XWB broker on port 9100."""

    def test_connect_and_disconnect(self, rpms_host: str, rpms_port: int) -> None:
        b = VistABroker(rpms_host, rpms_port)
        b.connect()
        assert b.is_connected
        assert b.state == SessionState.HANDSHAKED
        b.disconnect()
        assert not b.is_connected
        assert b.state == SessionState.DISCONNECTED

    def test_context_manager(self, rpms_host: str, rpms_port: int) -> None:
        with VistABroker(rpms_host, rpms_port) as b:
            assert b.is_connected
            assert b.state == SessionState.HANDSHAKED
        assert not b.is_connected
        assert b.state == SessionState.DISCONNECTED

    def test_connection_refused_wrong_port(self, rpms_host: str) -> None:
        with pytest.raises(BrokerConnectionError):
            VistABroker(rpms_host, 19999).connect()

    def test_bmx_broker_connect(self, rpms_host: str, rpms_bmx_port: int) -> None:
        """BMX broker on port 9101 accepts TCP connections."""
        with socket.create_connection((rpms_host, rpms_bmx_port), timeout=5.0):
            pass  # Connection accepted = success
