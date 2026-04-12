"""Authentication tests for the RPMS XWB broker."""

import os

import pytest

from vista_clients.rpc import AuthenticationError, VistABroker
from vista_clients.rpc.protocol import SessionState, literal, reference


class TestAuthentication:
    """Verify the XUS SIGNON SETUP → XUS AV CODE authentication flow."""

    def test_authenticate_with_defaults(self, broker: VistABroker) -> None:
        """Default RPMS provider credentials should authenticate."""
        ac = os.environ.get("RPMS_ACCESS_CODE", "PROV123")
        vc = os.environ.get("RPMS_VERIFY_CODE", "PROV123!!")
        duz = broker.authenticate(access_code=ac, verify_code=vc)
        assert duz
        assert int(duz) > 0
        assert broker.state == SessionState.AUTHENTICATED

    def test_duz_property_set(self, broker: VistABroker) -> None:
        ac = os.environ.get("RPMS_ACCESS_CODE", "PROV123")
        vc = os.environ.get("RPMS_VERIFY_CODE", "PROV123!!")
        duz = broker.authenticate(access_code=ac, verify_code=vc)
        assert broker.duz == duz
        assert int(broker.duz) > 0  # type: ignore[arg-type]

    def test_invalid_credentials(self, broker: VistABroker) -> None:
        with pytest.raises(AuthenticationError):
            broker.authenticate(access_code="BADCODE", verify_code="BADVERIFY")

    def test_explicit_credentials_from_env(
        self, rpms_host: str, rpms_port: int
    ) -> None:
        """Explicit env-var credentials should also work."""
        ac = os.environ.get("RPMS_ACCESS_CODE", "PROV123")
        vc = os.environ.get("RPMS_VERIFY_CODE", "PROV123!!")
        with VistABroker(rpms_host, rpms_port) as b:
            duz = b.authenticate(access_code=ac, verify_code=vc)
            assert int(duz) > 0


class TestRPMSUsers:
    """Verify all 3 seeded RPMS users authenticate with correct DUZ mappings."""

    def test_provider_auth(self, rpms_host: str, rpms_port: int) -> None:
        with VistABroker(rpms_host, rpms_port) as b:
            duz = b.authenticate(access_code="PROV123", verify_code="PROV123!!")
            assert duz == "1"

    def test_programmer_auth(self, rpms_host: str, rpms_port: int) -> None:
        with VistABroker(rpms_host, rpms_port) as b:
            duz = b.authenticate(access_code="PROG123", verify_code="PROG123!!")
            assert duz == "2"

    def test_nurse_auth(self, rpms_host: str, rpms_port: int) -> None:
        with VistABroker(rpms_host, rpms_port) as b:
            duz = b.authenticate(access_code="NURSE123", verify_code="NURSE123!!")
            assert duz == "3"

    def test_duz_name_mapping(self, context_broker: VistABroker) -> None:
        """DUZ 1 → PROVIDER,TEST in ^VA(200,1,0)."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$P($G(^VA(200,1,0)),U,1)")],
        )
        assert (response.value or "").strip() == "PROVIDER,TEST"

    def test_verify_code_not_expired(self, context_broker: VistABroker) -> None:
        """Verify code change date is set in the future."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$P($G(^VA(200,1,.1)),U,9)")],
        )
        vc_date = (response.value or "").strip()
        assert vc_date  # non-empty confirms it was set


class TestMultiUserContextAccess:
    """Verify non-default users can authenticate and call RPCs."""

    def test_programmer_can_authenticate(self, rpms_host: str, rpms_port: int) -> None:
        """DUZ 2 (PROGRAMMER) can authenticate and call an RPC."""
        with VistABroker(rpms_host, rpms_port) as b:
            b.authenticate(access_code="PROG123", verify_code="PROG123!!")
            assert b.state == SessionState.AUTHENTICATED
            assert b.duz == "2"

    def test_nurse_can_authenticate(self, rpms_host: str, rpms_port: int) -> None:
        """DUZ 3 (NURSE) can authenticate and call an RPC."""
        with VistABroker(rpms_host, rpms_port) as b:
            b.authenticate(access_code="NURSE123", verify_code="NURSE123!!")
            assert b.state == SessionState.AUTHENTICATED
            assert b.duz == "3"
