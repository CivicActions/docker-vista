"""Patient data tests for seeded RPMS test patients."""

from __future__ import annotations

import pytest

from vista_clients.rpc import VistABroker
from vista_clients.rpc.protocol import literal, reference


class TestPatientList:
    """Verify seeded patients are retrievable via RPCs and global reads."""

    def test_orwpt_list_all_returns_patients(self, context_broker: VistABroker) -> None:
        """ORWPT LIST ALL returns at least 2 seeded patients."""
        response = context_broker.call_rpc(
            "ORWPT LIST ALL", [literal(""), literal("1")]
        )
        lines = [line for line in (response.lines or []) if line.strip()]
        assert len(lines) >= 2

    def test_orwpt_id_info(self, context_broker: VistABroker) -> None:
        """ORWPT ID INFO returns demographics for a known DFN."""
        response = context_broker.call_rpc(
            "ORWPT ID INFO", [literal("100")]
        )
        value = (response.value or "").strip()
        assert value  # non-empty demographics string
        assert "^" in value  # caret-delimited fields

    def test_patient_name_via_global(self, context_broker: VistABroker) -> None:
        """Read patient name from ^DPT(100,0) via XWB GET VARIABLE VALUE."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$P($G(^DPT(100,0)),U,1)")],
        )
        name = (response.value or "").strip()
        assert name == "TESTPATIENT,ALICE"

    @pytest.mark.parametrize("dfn", ["100", "101"])
    def test_each_patient_has_demographics(
        self, context_broker: VistABroker, dfn: str
    ) -> None:
        """Each seeded patient has name, DOB, and gender."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference(f"$G(^DPT({dfn},0))")],
        )
        node = (response.value or "").strip()
        parts = node.split("^")
        assert len(parts) >= 3
        assert parts[0]  # name
        assert parts[1] in ("M", "F")  # gender
        assert parts[2]  # DOB


class TestExtendedDemographics:
    """Verify extended demographics (address, race, ethnicity) for seeded patients."""

    @pytest.mark.parametrize("dfn", ["100", "101"])
    def test_patient_has_address(
        self, context_broker: VistABroker, dfn: str
    ) -> None:
        """Each seeded patient has a street address."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference(f"$P($G(^DPT({dfn},.11)),U,1)")],
        )
        street = (response.value or "").strip()
        assert street, f"Patient {dfn} missing street address"

    @pytest.mark.parametrize("dfn", ["100", "101"])
    def test_patient_has_zip(
        self, context_broker: VistABroker, dfn: str
    ) -> None:
        """Each seeded patient has a zip code."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference(f"$P($G(^DPT({dfn},.11)),U,6)")],
        )
        zipcode = (response.value or "").strip()
        assert zipcode, f"Patient {dfn} missing zip code"

    @pytest.mark.parametrize("dfn", ["100", "101"])
    def test_patient_has_race(
        self, context_broker: VistABroker, dfn: str
    ) -> None:
        """Each seeded patient has race data in the RACE multiple."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference(f"$D(^DPT({dfn},\"RACE\"))")],
        )
        value = (response.value or "").strip()
        assert value and value != "0", f"Patient {dfn} missing race data"

    @pytest.mark.parametrize("dfn", ["100", "101"])
    def test_patient_has_ethnicity(
        self, context_broker: VistABroker, dfn: str
    ) -> None:
        """Each seeded patient has ethnicity data in the ETH multiple."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference(f"$D(^DPT({dfn},\"ETH\"))")],
        )
        value = (response.value or "").strip()
        assert value and value != "0", f"Patient {dfn} missing ethnicity data"
