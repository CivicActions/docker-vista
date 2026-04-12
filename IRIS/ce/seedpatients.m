ROUTINE seedpatients [Type=MAC]
seedpatients ; Seed test patients with clinical data for integration tests
 ;
 ; Creates 2 test patients in ^DPT with visits, problems, allergies,
 ; and vitals via direct global SETs.
 ;
 ; Patient 100: TESTPATIENT,ALICE — full clinical data (allergy, vitals, problems)
 ; Patient 101: TESTPATIENT,BOB  — minimal data (problem only, no allergies/vitals)
 ;
 WRITE "=== Seeding Test Patients ===",!
 ;
 DO PATIENT1
 DO PATIENT2
 DO HEADERS
 ;
 WRITE !,"=== Test Patient Seeding Complete ===",!
 WRITE "  Patient 100: TESTPATIENT,ALICE (DFN=100)",!
 WRITE "  Patient 101: TESTPATIENT,BOB  (DFN=101)",!
 QUIT
 ;
PATIENT1 ; --- Patient 100: TESTPATIENT,ALICE ---
 ;
 ; Demographics: Female, DOB Jan 15 1980, SSN 000000100
 SET ^DPT(100,0)="TESTPATIENT,ALICE^F^2800115^000000100"
 SET ^DPT("B","TESTPATIENT,ALICE",100)=""
 ;
 ; Extended demographics: address, race, ethnicity
 ; Node .11: street1^street2^street3^city^state(ptr)^zip
 SET ^DPT(100,.11)="123 TEST STREET^^^^6^12345"
 ; Race (sub-file 2.02 in RACE multiple)
 SET ^DPT(100,"RACE",0)="^2.02^1^1"
 SET ^DPT(100,"RACE",1,0)="3"
 ; Ethnicity (sub-file 2.06 in ETH multiple)
 SET ^DPT(100,"ETH",0)="^2.06^1^1"
 SET ^DPT(100,"ETH",1,0)="2"
 WRITE "  Patient 100: TESTPATIENT,ALICE - demographics OK",!
 ;
 ; Visit 1001: Ambulatory, Jan 1 2026 09:00
 ; Pieces: date^p2^p3^p4^patient_dfn^loc^service_cat
 SET ^AUPNVSIT(1001,0)="3260101.09^^^^100^1^A"
 ; AA xref: patient -> inverse_date -> visit
 ; Inverse date = 9999999 - 3260101 = 6739898
 SET ^AUPNVSIT("AA",100,6739898,1001)=""
 WRITE "  Patient 100: Visit 1001 - OK",!
 ;
 ; Purpose of Visit: ICD-10-CM I10 (Essential Hypertension)
 ; Pieces: pov_ptr^patient_dfn^visit_ien^icd_code
 SET ^AUPNVPOV(1,0)="^100^1001^I10"
 SET ^AUPNVPOV("AD",1001,1)=""
 WRITE "  Patient 100: POV (I10 Hypertension) - OK",!
 ;
 ; Problem: Active Hypertension (ICD-10-CM I10, SNOMED 38341003)
 ; Pieces: diagnosis^patient^p3^date_entered^p5-p11^status(p12)^icd_code(p13)^snomed(p14)
 SET ^AUPNPROB(1,0)="HYPERTENSION^100^^3260101^^^^^^^^A^I10^38341003"
 SET ^AUPNPROB("AC",100,1)=""
 SET ^AUPNPROB(1,14,"B",1001)=""
 WRITE "  Patient 100: Problem (Hypertension, I10/38341003) - OK",!
 ;
 ; Allergy: Penicillin (drug allergy, SNOMED 91936005)
 ; Pieces: patient_dfn^reactant^p3^p4^allergy_type^snomed_code
 SET ^GMR(120.8,1,0)="100^PENICILLIN^^^D^91936005"
 SET ^GMR(120.8,"B",100,1)=""
 WRITE "  Patient 100: Allergy (Penicillin, SNOMED 91936005) - OK",!
 ;
 ; Vitals: BP, Pulse, Temp for Visit 1001
 ; Pieces: vital_type^value^patient_dfn^visit_ien^date_time^units^loinc
 SET ^AUPNVMSR(1,0)="1^120/80^100^1001^3260101.09^mmHg^85354-9"
 SET ^AUPNVMSR(2,0)="2^72^100^1001^3260101.09^/min^8867-4"
 SET ^AUPNVMSR(3,0)="3^98.6^100^1001^3260101.09^[degF]^8310-5"
 WRITE "  Patient 100: Vitals (BP, Pulse, Temp with LOINC/UCUM) - OK",!
 ;
 ; Medication: Lisinopril 10mg daily (active prescription)
 ; ^PSRX: outpatient prescription, ^PS(55): patient medication profile
 SET ^PSRX(1,0)="RX100001^100^1^^^1^^^3260101"
 SET ^PSRX(1,2)="3260101^30^30"
 SET ^PSRX(1,6)="LISINOPRIL 10MG TAB"
 SET ^PSRX(1,"STA")=0
 SET ^PSRX("B","RX100001",1)=""
 SET ^PS(55,100,0)=100
 SET ^PS(55,100,"P",0)="^52.1PA^1^1"
 SET ^PS(55,100,"P",1,0)=1
 WRITE "  Patient 100: Medication (Lisinopril) - OK",!
 ;
 ; Lab Result: Glucose 100 mg/dL (LOINC 2345-7)
 ; Link patient to lab file via ^DPT(DFN,"LR")=LRDFN
 SET ^DPT(100,"LR")=100
 SET ^LR(100,0)="100^2"
 ; CH subscript: date_inverse,test_ien = result data
 ; Pieces: p1^test_name^value^flag^units^ref_low^ref_high^loinc
 SET ^LR(100,"CH",6739898,1)="^GLUCOSE^100^^mg/dL^70^110^2345-7"
 WRITE "  Patient 100: Lab (Glucose, LOINC 2345-7) - OK",!
 ;
 ; Immunization: Influenza (CVX 141) linked to visit 1001
 ; V IMMUNIZATION file (9000010.11)
 ; Pieces: visit_ptr^patient_dfn^imm_ptr^series^reaction^date^cvx_code
 SET ^AUPNVIMM(1,0)="1001^100^1^C^^^141"
 SET ^AUPNVIMM("AA",100,6739898,1)=""
 SET ^AUPNVIMM("AD",1001,1)=""
 WRITE "  Patient 100: Immunization (Influenza, CVX 141) - OK",!
 ;
 QUIT
 ;
PATIENT2 ; --- Patient 101: TESTPATIENT,BOB ---
 ;
 ; Demographics: Male, DOB Jun 20 1975, SSN 000000101
 SET ^DPT(101,0)="TESTPATIENT,BOB^M^2750620^000000101"
 SET ^DPT("B","TESTPATIENT,BOB",101)=""
 ;
 ; Extended demographics: address, race, ethnicity
 SET ^DPT(101,.11)="456 SAMPLE AVENUE^^^^10^67890"
 SET ^DPT(101,"RACE",0)="^2.02^1^1"
 SET ^DPT(101,"RACE",1,0)="5"
 SET ^DPT(101,"ETH",0)="^2.06^1^1"
 SET ^DPT(101,"ETH",1,0)="1"
 WRITE "  Patient 101: TESTPATIENT,BOB - demographics OK",!
 ;
 ; Visit 1002: Ambulatory, Feb 15 2026 14:00
 SET ^AUPNVSIT(1002,0)="3260215.14^^^^101^1^A"
 ; Inverse date = 9999999 - 3260215 = 6739784
 SET ^AUPNVSIT("AA",101,6739784,1002)=""
 WRITE "  Patient 101: Visit 1002 - OK",!
 ;
 ; Purpose of Visit: ICD-10-CM E11.9 (Type 2 Diabetes Mellitus)
 SET ^AUPNVPOV(2,0)="^101^1002^E11.9"
 SET ^AUPNVPOV("AD",1002,2)=""
 WRITE "  Patient 101: POV (E11.9 Diabetes) - OK",!
 ;
 ; Problem: Active Diabetes (ICD-10-CM E11.9, SNOMED 44054006)
 SET ^AUPNPROB(2,0)="DIABETES MELLITUS^101^^3260215^^^^^^^^A^E11.9^44054006"
 SET ^AUPNPROB("AC",101,2)=""
 SET ^AUPNPROB(2,14,"B",1002)=""
 WRITE "  Patient 101: Problem (Diabetes, E11.9/44054006) - OK",!
 ;
 ; NOTE: Patient 101 intentionally has NO allergies, NO vitals,
 ; NO medications, NO labs, and NO immunizations
 ; to test empty/no-data response paths
 ;
 QUIT
 ;
HEADERS ; --- Update file header nodes ---
 ;
 ; ^DPT(0): PATIENT file header — last IEN, count
 ; Only update if our IENs are higher than existing
 NEW LASTIEN
 SET LASTIEN=$PIECE($GET(^DPT(0)),"^",3)
 IF LASTIEN<101 SET $PIECE(^DPT(0),"^",3)=101
 SET $PIECE(^DPT(0),"^",4)=$ORDER(^DPT(0))
 ;
 ; ^AUPNVSIT(0): Visit file header
 SET LASTIEN=$PIECE($GET(^AUPNVSIT(0)),"^",3)
 IF LASTIEN<1002 SET $PIECE(^AUPNVSIT(0),"^",3)=1002
 ;
 ; ^AUPNVPOV(0): POV file header
 SET LASTIEN=$PIECE($GET(^AUPNVPOV(0)),"^",3)
 IF LASTIEN<2 SET $PIECE(^AUPNVPOV(0),"^",3)=2
 ;
 ; ^AUPNPROB(0): Problem file header
 SET LASTIEN=$PIECE($GET(^AUPNPROB(0)),"^",3)
 IF LASTIEN<2 SET $PIECE(^AUPNPROB(0),"^",3)=2
 ;
 ; ^AUPNVMSR(0): V Measurement file header
 SET LASTIEN=$PIECE($GET(^AUPNVMSR(0)),"^",3)
 IF LASTIEN<3 SET $PIECE(^AUPNVMSR(0),"^",3)=3
 ;
 ; ^GMR(120.8,0): Patient Allergies file header
 SET LASTIEN=$PIECE($GET(^GMR(120.8,0)),"^",3)
 IF LASTIEN<1 SET $PIECE(^GMR(120.8,0),"^",3)=1
 ;
 ; ^PSRX(0): Prescription file header
 SET LASTIEN=$PIECE($GET(^PSRX(0)),"^",3)
 IF LASTIEN<1 SET $PIECE(^PSRX(0),"^",3)=1
 ;
 ; ^LR(0): Lab Results file header
 SET LASTIEN=$PIECE($GET(^LR(0)),"^",3)
 IF LASTIEN<100 SET $PIECE(^LR(0),"^",3)=100
 ;
 ; ^AUPNVIMM(0): V Immunization file header
 SET LASTIEN=$PIECE($GET(^AUPNVIMM(0)),"^",3)
 IF LASTIEN<1 SET $PIECE(^AUPNVIMM(0),"^",3)=1
 ;
 WRITE "  File headers updated",!
 QUIT
