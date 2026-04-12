"""RPC invocation tests for the RPMS XWB broker."""

import pytest

from vista_clients.rpc import RPCError, VistABroker
from vista_clients.rpc.protocol import literal, reference


class TestRPCInvocation:
    """Call RPCs under OR CPRS GUI CHART and verify responses."""

    def test_orwu_userinfo(self, context_broker: VistABroker) -> None:
        """ORWU USERINFO returns user metadata (multi-line)."""
        response = context_broker.call_rpc("ORWU USERINFO")
        assert response.raw

    def test_xwb_get_variable_duz(self, context_broker: VistABroker) -> None:
        """XWB GET VARIABLE VALUE with literal('DUZ') returns the authenticated DUZ."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE", [reference("DUZ")]
        )
        # The response value should match the broker's DUZ
        result = (response.value or "").strip()
        assert result == context_broker.duz

    def test_xwb_get_variable_global(self, context_broker: VistABroker) -> None:
        """Read a global reference via XWB GET VARIABLE VALUE."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$P($G(^DIC(3.1,1,0)),U,1)")],
        )
        assert response is not None

    def test_nonexistent_rpc_raises(self, context_broker: VistABroker) -> None:
        with pytest.raises(RPCError):
            context_broker.call_rpc("NONEXISTENT RPC 12345")

    def test_ping_keepalive(self, context_broker: VistABroker) -> None:
        """broker.ping() should succeed without error."""
        context_broker.ping()
        # After ping we can still call RPCs
        response = context_broker.call_rpc("ORWU USERINFO")
        assert response.raw
