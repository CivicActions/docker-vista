"""Context creation and switching tests for the RPMS XWB broker."""

import pytest

from vista_clients.rpc import ContextError, VistABroker
from vista_clients.rpc.protocol import SessionState


class TestContext:
    """XWB CREATE CONTEXT against known RPMS option names."""

    def test_create_context_or_cprs_gui_chart(
        self, authenticated_broker: VistABroker
    ) -> None:
        """OR CPRS GUI CHART should exist — RPMS ships Order Entry."""
        authenticated_broker.create_context("OR CPRS GUI CHART")
        assert authenticated_broker.state == SessionState.CONTEXT_SET

    def test_create_context_xwb_broker_example(
        self, authenticated_broker: VistABroker
    ) -> None:
        """XWB BROKER EXAMPLE is the standard RPC Broker test context."""
        authenticated_broker.create_context("XWB BROKER EXAMPLE")
        assert authenticated_broker.state == SessionState.CONTEXT_SET

    def test_create_context_invalid(self, authenticated_broker: VistABroker) -> None:
        with pytest.raises(ContextError):
            authenticated_broker.create_context("TOTALLY BOGUS CONTEXT 99999")

    def test_switch_context(self, authenticated_broker: VistABroker) -> None:
        authenticated_broker.create_context("OR CPRS GUI CHART")
        assert authenticated_broker.state == SessionState.CONTEXT_SET
        # Switch to a different context
        authenticated_broker.create_context("XWB BROKER EXAMPLE")
        assert authenticated_broker.state == SessionState.CONTEXT_SET

    def test_create_context_xuprogmode(
        self, authenticated_broker: VistABroker
    ) -> None:
        """XUPROGMODE (programmer mode) context should be registered."""
        authenticated_broker.create_context("XUPROGMODE")
        assert authenticated_broker.state == SessionState.CONTEXT_SET
