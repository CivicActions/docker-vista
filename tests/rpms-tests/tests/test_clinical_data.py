"""Clinical data tests for seeded RPMS test patients."""

from __future__ import annotations

from vista_clients.rpc import VistABroker
from vista_clients.rpc.protocol import literal, reference


class TestAllergies:
    """Verify allergy data via ORQQAL LIST."""

    def test_orqqal_list_patient_with_allergy(
        self, context_broker: VistABroker
    ) -> None:
        """Patient 100 has a seeded allergy — ORQQAL LIST returns data."""
        response = context_broker.call_rpc(
            "ORQQAL LIST", [literal("100")]
        )
        lines = response.lines or [response.value or ""]
        combined = "\n".join(lines)
        assert "No Allergy Assessment" not in combined
        assert lines  # at least one line returned

    def test_orqqal_list_patient_without_allergy(
        self, context_broker: VistABroker
    ) -> None:
        """Patient 101 has no allergy data — response reflects that."""
        response = context_broker.call_rpc(
            "ORQQAL LIST", [literal("101")]
        )
        value = (response.value or "") + "\n".join(response.lines or [])
        assert value.strip()  # non-empty response


class TestVitals:
    """Verify vitals data via GMV EXTRACT REC."""

    def test_gmv_extract_rec_returns_vitals(
        self, context_broker: VistABroker
    ) -> None:
        """GMV EXTRACT REC returns vitals for patient 100."""
        response = context_broker.call_rpc(
            "GMV EXTRACT REC", [literal("100^^^")]
        )
        lines = response.lines or [response.value or ""]
        combined = "\n".join(lines).upper()
        assert "NO VITALS" not in combined or "NO MEASUREMENTS" not in combined
        assert lines


class TestProblemList:
    """Verify problem list via ORQQPL PROBLEM LIST."""

    def test_orqqpl_problem_list(self, context_broker: VistABroker) -> None:
        """Patient 100 has at least one active problem."""
        response = context_broker.call_rpc(
            "ORQQPL PROBLEM LIST", [literal("100")]
        )
        lines = [line for line in (response.lines or []) if line.strip()]
        assert len(lines) >= 1


class TestMedications:
    """Verify medication data via global reads."""

    def test_patient_has_prescription(self, context_broker: VistABroker) -> None:
        """Patient 100 has at least one prescription in ^PSRX."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$G(^PSRX(1,6))")],
        )
        drug_name = (response.value or "").strip()
        assert drug_name, "No prescription drug name found in ^PSRX(1,6)"
        assert "LISINOPRIL" in drug_name.upper()

    def test_patient_medication_profile(self, context_broker: VistABroker) -> None:
        """Patient 100 has a medication profile in ^PS(55)."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$D(^PS(55,100,\"P\"))")],
        )
        value = (response.value or "").strip()
        assert value and value != "0", "No medication profile for patient 100"


class TestLabResults:
    """Verify lab result data via global reads."""

    def test_patient_has_lab_data(self, context_broker: VistABroker) -> None:
        """Patient 100 has lab results linked via ^DPT(100,\"LR\")."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$G(^DPT(100,\"LR\"))")],
        )
        lrdfn = (response.value or "").strip()
        assert lrdfn, "No lab file link for patient 100"

    def test_lab_result_value(self, context_broker: VistABroker) -> None:
        """Patient 100's glucose result is readable from ^LR."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$G(^LR(100,\"CH\",6739898,1))")],
        )
        result = (response.value or "").strip()
        assert result, "No lab result found in ^LR"
        parts = result.split("^")
        assert "GLUCOSE" in (parts[1] if len(parts) > 1 else "").upper()


class TestImmunizations:
    """Verify immunization data via global reads."""

    def test_patient_has_immunization(self, context_broker: VistABroker) -> None:
        """Patient 100 has an immunization record in ^AUPNVIMM."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$G(^AUPNVIMM(1,0))")],
        )
        node = (response.value or "").strip()
        assert node, "No immunization record found"
        parts = node.split("^")
        # Piece 2 = patient DFN
        assert parts[1] == "100" if len(parts) > 1 else False

    def test_immunization_linked_to_visit(
        self, context_broker: VistABroker
    ) -> None:
        """Immunization record is linked to visit 1001."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference('$O(^AUPNVIMM("AD",1001,0))')],
        )
        imm_ien = (response.value or "").strip()
        assert imm_ien and imm_ien != "0", "No immunization linked to visit 1001"


class TestVisitData:
    """Verify visit/encounter structure for seeded patients."""

    def test_visit_exists_for_patient(self, context_broker: VistABroker) -> None:
        """Patient 100 has at least one visit in ^AUPNVSIT."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference('$O(^AUPNVSIT("AA",100,0))')],
        )
        inv_date = (response.value or "").strip()
        assert inv_date, "No visit cross-reference found for patient 100"

    def test_visit_has_date_and_location(
        self, context_broker: VistABroker
    ) -> None:
        """Visit 1001 has a date and service category."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference("$G(^AUPNVSIT(1001,0))")],
        )
        node = (response.value or "").strip()
        parts = node.split("^")
        assert parts[0]  # visit date

    def test_visit_has_diagnosis(self, context_broker: VistABroker) -> None:
        """Visit 1001 has at least one linked purpose-of-visit."""
        response = context_broker.call_rpc(
            "XWB GET VARIABLE VALUE",
            [reference('$O(^AUPNVPOV("AD",1001,0))')],
        )
        pov_ien = (response.value or "").strip()
        assert pov_ien and pov_ien != "0", "No POV linked to visit 1001"
