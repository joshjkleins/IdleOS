# Items.gd (autoload)
extends Node
## ADDING ITEMS ##
# Add to ItemType enum
# Remember ID (commented number)
# create resource in items directory 
# assign id (same as ItemType)
# add preload
# add to ITEM_MAP (order not important here(ithink))

## ADDING VALUABLES ##
# Same as above but add to valuables directory and check valuable bool in resource

## ADDING CACHE ##
# Create cache_entry (in appropriate directory) for each item that will be in cache e.g. student_data will be Data and have a min of 1 and max of 10 with a 1.0 (100%) drop chance
# note: drop chance is independent, not weighted. so if its set to 1.0, it will always drop EXCEPT rare drops, then drop chance is ignored in cache_entry
# Once they are all created, create a cache_data resource (again in appropriate directory). and drag cache_entry's to appropriate slots (regular drops & rare drops)
# When creating cache_data resource make sure you follow "ADDING ITEMS" instructions as the ID will matter in ItemType enum
# Once it is created and assigned in this file, go to Stats.gd and assign to appropriate target


enum ItemType {
	DATA, #0
	LOGS, #1
	ENCRYPTED_PASSWORDS, #2
	PASSWORDS, #3
	USERNAMES, #4
	CREDENTIALS, #5
	IP_ADDRESS, #6
	PARENTS_CREDIT_CARD, #7
	STUDENT_CACHE, #8
	FALSIFIED_TRANSCRIPT_DATABASE, #9
	ADMIN_CACHE, #10
	STUDENT_DISCIPLINARY_RECORDS, #11
	SCHOOL_BUDGET_EMBEZZLEMENT_LOGS, #12
	DISTRICT_WIDE_MASTER_PASSWORD, #13
	VICE_PRINCIPAL_CACHE, #14
	PRINCIPAL_CACHE, #15
	SUPERINTENDENT_CACHE, #16
	BORROWED_BOOK_HISTORY, #17
	INTERNAL_STAFF_LOGIN_CREDENTIALS, #18
	DIGITIZED_RARE_BOOK_SCAN, #19
	OVERDUE_FINE_WAIVER_DATABASE, #20
	CENSORED_BOOKS_ARCHIVE, #21
	PATRON_CACHE, #22
	VOLUNTEER_CACHE, #23
	ASSISTANT_LIBRARIAN_CACHE, #24
	HEAD_LIBRARIAN_CACHE, #25
	DIRECTOR_CACHE, #26
	EMPLOYEE_PAYROLL_DATA, #27
	SHIFT_SCHEDULE_AND_SECURITY_ROTATION, #28
	SUPPLIER_CONTACT_LIST, #29
	CONFIDENTIAL_HR_COMPLAINT_FILES, #30
	UNRELEASED_PRODUCT_PROTOTYPE, #31
	WORKER_CACHE, #32
	SUPERVISOR_CACHE, #33
	MANAGER_CACHE, #34
	HUMAN_RESOURCES_CACHE, #35
	OWNER_CACHE, #36
	STOLEN_EXAM_ANSWER_KEY, #37
	UNPUBLISHED_RESEARCH_PAPER, #38
	GRANT_FRAUD_DOCUMENTATION, #39
	ADMISSIONS_BRIBERY_RECORDS, #40
	ENDOWMENT_FUND_ACCESS_CODES, #41
	TEACHERS_ASSISTANT_CACHE, #42
	PROFESSOR_CACHE, #43
	DEPARTMENT_CHAIR_CACHE, #44
	DEAN_CACHE, #45
	UNIVERSITY_PRESIDENT_CACHE, #46
	PATIENT_APPOINTMENT_HISTORY, #47
	STAFF_KEYCARD_CLONE_DATA, #48
	PRESCRIPTION_PAD_CREDENTIALS, #49
	PATIENT_INSURANCE_DATA, #50
	FALSIFIED_DRUG_TRIAL_RESULTS, #51
	RECEPTIONIST_CACHE, #52
	ORDERLY_CACHE, #53
	NURSE_CACHE, #54
	DOCTOR_CACHE, #55
	CHIEF_OF_MEDICINE_CACHE, #56
	INTERNAL_AFFAIRS_COMPLAINT_ARCHIVE, #57
	BODY_CAM_FOOTAGE_DELETION_LOGS, #58
	CONFIDENTIAL_INFORMANT_REGISTRY, #59
	EVIDENCE_LOCKER_ACCESS_CODES, #60
	CORRUPTION_PAYOUT_LEDGER, #61
	SECRETARY_CACHE, #62
	COP_CACHE, #63
	DETECTIVE_CACHE, #64
	SERGEANT_CACHE, #65
	CAPTAIN_CACHE, #66
	LEAKED_DEPOSITION_TRANSCRIPTS, #67
	FORGED_COURT_DOCUMENT_TEMPLATES, #68
	SEALED_CASE_FILES, #69
	OFFSHORE_ACCOUNT_RECORDS, #70
	WITNESS_PROTECTION_ADDRESS, #71
	LEGAL_ASSISTANT_CACHE, #72
	PARALEGAL_CACHE, #73
	ASSOCIATE_ATTORNEY_CACHE, #74
	LAWYER_CACHE, #75
	PARTNER_CACHE, #76
}

#items
const DATA = preload("res://items/data.tres")
const LOGS = preload("res://items/logs.tres")
const ENCRYPTED_PASSWORDS = preload("res://items/encrypted_passwords.tres")
const PASSWORDS = preload("res://items/passwords.tres")
const USERNAMES = preload("res://items/usernames.tres")
const CREDENTIALS = preload("res://items/credentials.tres")
const IP_ADDRESS = preload("res://items/ip_address.tres")

### VALUABLES ###
#school
const PARENTS_CREDIT_CARD = preload("res://items/valuables/school/parents_credit_card.tres")
const FALSIFIED_TRANSCRIPT_DATABASE = preload("res://items/valuables/school/falsified_transcript_database.tres")
const STUDENT_DISCIPLINARY_RECORDS = preload("res://items/valuables/school/student_disciplinary_records.tres")
const SCHOOL_BUDGET_EMBEZZLEMENT_LOGS = preload("res://items/valuables/school/school_budget_embezzlement_logs.tres")
const DISTRICT_WIDE_MASTER_PASSWORD = preload("res://items/valuables/school/district_wide_master_password.tres")
#library
const BORROWED_BOOK_HISTORY = preload("res://items/valuables/library/borrowed_book_history.tres")
const INTERNAL_STAFF_LOGIN_CREDENTIALS = preload("res://items/valuables/library/internal_staff_login_credentials.tres")
const DIGITIZED_RARE_BOOK_SCAN = preload("res://items/valuables/library/digitized_rare_book_scan.tres")
const OVERDUE_FINE_WAIVER_DATABASE = preload("res://items/valuables/library/overdue_fine_waiver_database.tres")
const CENSORED_BOOKS_ARCHIVE = preload("res://items/valuables/library/censored_books_archive.tres")
#small business
const EMPLOYEE_PAYROLL_DATA = preload("res://items/valuables/small_business/employee_payroll_data.tres")
const SHIFT_SCHEDULE_AND_SECURITY_ROTATION = preload("res://items/valuables/small_business/shift_schedule_and_security_rotation.tres")
const SUPPLIER_CONTACT_LIST = preload("res://items/valuables/small_business/supplier_contact_list.tres")
const CONFIDENTIAL_HR_COMPLAINT_FILES = preload("res://items/valuables/small_business/confidential_hr_complaint_files.tres")
const UNRELEASED_PRODUCT_PROTOTYPE = preload("res://items/valuables/small_business/unreleased_product_prototype.tres")
#university
const STOLEN_EXAM_ANSWER_KEY = preload("res://items/valuables/university/stolen_exam_answer_key.tres")
const UNPUBLISHED_RESEARCH_PAPER = preload("res://items/valuables/university/unpublished_research_paper.tres")
const GRANT_FRAUD_DOCUMENTATION = preload("res://items/valuables/university/grant_fraud_documentation.tres")
const ADMISSIONS_BRIBERY_RECORDS = preload("res://items/valuables/university/admissions_bribery_records.tres")
const ENDOWMENT_FUND_ACCESS_CODES = preload("res://items/valuables/university/endowment_fund_access_codes.tres")
#hospital
const PATIENT_APPOINTMENT_HISTORY = preload("res://items/valuables/hospital/patient_appointment_history.tres")
const STAFF_KEYCARD_CLONE_DATA = preload("res://items/valuables/hospital/staff_keycard_clone_data.tres")
const PRESCRIPTION_PAD_CREDENTIALS = preload("res://items/valuables/hospital/prescription_pad_credentials.tres")
const PATIENT_INSURANCE_DATA = preload("res://items/valuables/hospital/patient_insurance_data.tres")
const FALSIFIED_DRUG_TRIAL_RESULTS = preload("res://items/valuables/hospital/falsified_drug_trial_results.tres")
#police station
const INTERNAL_AFFAIRS_COMPLAINT_ARCHIVE = preload("res://items/valuables/police_station/internal_affairs_complaint_archive.tres")
const BODY_CAM_FOOTAGE_DELETION_LOGS = preload("res://items/valuables/police_station/body_cam_footage_deletion_logs.tres")
const CONFIDENTIAL_INFORMANT_REGISTRY = preload("res://items/valuables/police_station/confidential_informant_registry.tres")
const EVIDENCE_LOCKER_ACCESS_CODES = preload("res://items/valuables/police_station/evidence_locker_access_codes.tres")
const CORRUPTION_PAYOUT_LEDGER = preload("res://items/valuables/police_station/corruption_payout_ledger.tres")
#lawfirm
const LEAKED_DEPOSITION_TRANSCRIPTS = preload("res://items/valuables/lawfirm/leaked_deposition_transcripts.tres")
const FORGED_COURT_DOCUMENT_TEMPLATES = preload("res://items/valuables/lawfirm/forged_court_document_templates.tres")
const SEALED_CASE_FILES = preload("res://items/valuables/lawfirm/sealed_case_files.tres")
const OFFSHORE_ACCOUNT_RECORDS = preload("res://items/valuables/lawfirm/offshore_account_records.tres")
const WITNESS_PROTECTION_ADDRESS = preload("res://items/valuables/lawfirm/witness_protection_address.tres")

### CACHES ###

#school
const STUDENT_CACHE = preload("res://items/cache_data/school/student_cache.tres")
const ADMIN_CACHE = preload("res://items/cache_data/school/admin_cache.tres")
const VICE_PRINCIPAL_CACHE = preload("res://items/cache_data/school/vice_principal_cache.tres")
const PRINCIPAL_CACHE = preload("res://items/cache_data/school/principal_cache.tres")
const SUPERINTENDENT_CACHE = preload("res://items/cache_data/school/superintendent_cache.tres")

#library
const PATRON_CACHE = preload("res://items/cache_data/library/patron_cache.tres")
const VOLUNTEER_CACHE = preload("res://items/cache_data/library/volunteer_cache.tres")
const ASSISTANT_LIBRARIAN_CACHE = preload("res://items/cache_data/library/assistant_librarian_cache.tres")
const HEAD_LIBRARIAN_CACHE = preload("res://items/cache_data/library/head_librarian_cache.tres")
const DIRECTOR_CACHE = preload("res://items/cache_data/library/director_cache.tres")

#small business
const WORKER_CACHE = preload("res://items/cache_data/small_business/worker_cache.tres")
const SUPERVISOR_CACHE = preload("res://items/cache_data/small_business/supervisor_cache.tres")
const MANAGER_CACHE = preload("res://items/cache_data/small_business/manager_cache.tres")
const HUMAN_RESOURCES_CACHE = preload("res://items/cache_data/small_business/human_resources_cache.tres")
const OWNER_CACHE = preload("res://items/cache_data/small_business/owner_cache.tres")

#university
const TEACHERS_ASSISTANT_CACHE = preload("res://items/cache_data/university/teachers_assistant_cache.tres")
const PROFESSOR_CACHE = preload("res://items/cache_data/university/professor_cache.tres")
const DEPARTMENT_CHAIR_CACHE = preload("res://items/cache_data/university/department_chair_cache.tres")
const DEAN_CACHE = preload("res://items/cache_data/university/dean_cache.tres")
const UNIVERSITY_PRESIDENT_CACHE = preload("res://items/cache_data/university/university_president_cache.tres")

#hospital
const RECEPTIONIST_CACHE = preload("res://items/cache_data/hospital/receptionist_cache.tres")
const ORDERLY_CACHE = preload("res://items/cache_data/hospital/orderly_cache.tres")
const NURSE_CACHE = preload("res://items/cache_data/hospital/nurse_cache.tres")
const DOCTOR_CACHE = preload("res://items/cache_data/hospital/doctor_cache.tres")
const CHIEF_OF_MEDICINE_CACHE = preload("res://items/cache_data/hospital/chief_of_medicine_cache.tres")

#police station
const SECRETARY_CACHE = preload("res://items/cache_data/police_station/secretary_cache.tres")
const COP_CACHE = preload("res://items/cache_data/police_station/cop_cache.tres")
const DETECTIVE_CACHE = preload("res://items/cache_data/police_station/detective_cache.tres")
const SERGEANT_CACHE = preload("res://items/cache_data/police_station/sergeant_cache.tres")
const CAPTAIN_CACHE = preload("res://items/cache_data/police_station/captain_cache.tres")

#law firm
const LEGAL_ASSISTANT_CACHE = preload("res://items/cache_data/law_firm/legal_assistant_cache.tres")
const PARALEGAL_CACHE = preload("res://items/cache_data/law_firm/paralegal_cache.tres")
const ASSOCIATE_ATTORNEY_CACHE = preload("res://items/cache_data/law_firm/associate_attorney_cache.tres")
const LAWYER_CACHE = preload("res://items/cache_data/law_firm/lawyer_cache.tres")
const PARTNER_CACHE = preload("res://items/cache_data/law_firm/partner_cache.tres")

const ITEM_MAP = {
	ItemType.DATA: DATA,
	ItemType.LOGS: LOGS,
	ItemType.ENCRYPTED_PASSWORDS: ENCRYPTED_PASSWORDS,
	ItemType.PASSWORDS: PASSWORDS,
	ItemType.USERNAMES: USERNAMES,
	ItemType.CREDENTIALS: CREDENTIALS,
	ItemType.IP_ADDRESS: IP_ADDRESS,
	ItemType.PARENTS_CREDIT_CARD: PARENTS_CREDIT_CARD,
	ItemType.STUDENT_CACHE: STUDENT_CACHE,
	ItemType.FALSIFIED_TRANSCRIPT_DATABASE: FALSIFIED_TRANSCRIPT_DATABASE,
	ItemType.ADMIN_CACHE: ADMIN_CACHE,
	ItemType.STUDENT_DISCIPLINARY_RECORDS: STUDENT_DISCIPLINARY_RECORDS,
	ItemType.SCHOOL_BUDGET_EMBEZZLEMENT_LOGS: SCHOOL_BUDGET_EMBEZZLEMENT_LOGS,
	ItemType.DISTRICT_WIDE_MASTER_PASSWORD: DISTRICT_WIDE_MASTER_PASSWORD,
	ItemType.VICE_PRINCIPAL_CACHE: VICE_PRINCIPAL_CACHE,
	ItemType.PRINCIPAL_CACHE: PRINCIPAL_CACHE,
	ItemType.SUPERINTENDENT_CACHE: SUPERINTENDENT_CACHE,
	ItemType.BORROWED_BOOK_HISTORY: BORROWED_BOOK_HISTORY,
	ItemType.INTERNAL_STAFF_LOGIN_CREDENTIALS: INTERNAL_STAFF_LOGIN_CREDENTIALS,
	ItemType.DIGITIZED_RARE_BOOK_SCAN: DIGITIZED_RARE_BOOK_SCAN,
	ItemType.OVERDUE_FINE_WAIVER_DATABASE: OVERDUE_FINE_WAIVER_DATABASE,
	ItemType.CENSORED_BOOKS_ARCHIVE: CENSORED_BOOKS_ARCHIVE,
	ItemType.PATRON_CACHE: PATRON_CACHE,
	ItemType.VOLUNTEER_CACHE: VOLUNTEER_CACHE,
	ItemType.ASSISTANT_LIBRARIAN_CACHE: ASSISTANT_LIBRARIAN_CACHE,
	ItemType.HEAD_LIBRARIAN_CACHE: HEAD_LIBRARIAN_CACHE,
	ItemType.DIRECTOR_CACHE: DIRECTOR_CACHE,
	ItemType.EMPLOYEE_PAYROLL_DATA: EMPLOYEE_PAYROLL_DATA,
	ItemType.SHIFT_SCHEDULE_AND_SECURITY_ROTATION: SHIFT_SCHEDULE_AND_SECURITY_ROTATION,
	ItemType.SUPPLIER_CONTACT_LIST: SUPPLIER_CONTACT_LIST,
	ItemType.CONFIDENTIAL_HR_COMPLAINT_FILES: CONFIDENTIAL_HR_COMPLAINT_FILES,
	ItemType.UNRELEASED_PRODUCT_PROTOTYPE: UNRELEASED_PRODUCT_PROTOTYPE,
	ItemType.WORKER_CACHE: WORKER_CACHE,
	ItemType.SUPERVISOR_CACHE: SUPERVISOR_CACHE,
	ItemType.MANAGER_CACHE: MANAGER_CACHE,
	ItemType.HUMAN_RESOURCES_CACHE: HUMAN_RESOURCES_CACHE,
	ItemType.OWNER_CACHE: OWNER_CACHE,
	ItemType.STOLEN_EXAM_ANSWER_KEY: STOLEN_EXAM_ANSWER_KEY,
	ItemType.UNPUBLISHED_RESEARCH_PAPER: UNPUBLISHED_RESEARCH_PAPER,
	ItemType.GRANT_FRAUD_DOCUMENTATION: GRANT_FRAUD_DOCUMENTATION,
	ItemType.ADMISSIONS_BRIBERY_RECORDS: ADMISSIONS_BRIBERY_RECORDS,
	ItemType.ENDOWMENT_FUND_ACCESS_CODES: ENDOWMENT_FUND_ACCESS_CODES,
	ItemType.TEACHERS_ASSISTANT_CACHE: TEACHERS_ASSISTANT_CACHE,
	ItemType.PROFESSOR_CACHE: PROFESSOR_CACHE,
	ItemType.DEPARTMENT_CHAIR_CACHE: DEPARTMENT_CHAIR_CACHE,
	ItemType.DEAN_CACHE: DEAN_CACHE,
	ItemType.UNIVERSITY_PRESIDENT_CACHE: UNIVERSITY_PRESIDENT_CACHE,
	ItemType.PATIENT_APPOINTMENT_HISTORY: PATIENT_APPOINTMENT_HISTORY,
	ItemType.STAFF_KEYCARD_CLONE_DATA: STAFF_KEYCARD_CLONE_DATA,
	ItemType.PRESCRIPTION_PAD_CREDENTIALS: PRESCRIPTION_PAD_CREDENTIALS,
	ItemType.PATIENT_INSURANCE_DATA: PATIENT_INSURANCE_DATA,
	ItemType.FALSIFIED_DRUG_TRIAL_RESULTS: FALSIFIED_DRUG_TRIAL_RESULTS,
	ItemType.RECEPTIONIST_CACHE: RECEPTIONIST_CACHE,
	ItemType.ORDERLY_CACHE: ORDERLY_CACHE,
	ItemType.NURSE_CACHE: NURSE_CACHE,
	ItemType.DOCTOR_CACHE: DOCTOR_CACHE,
	ItemType.CHIEF_OF_MEDICINE_CACHE: CHIEF_OF_MEDICINE_CACHE,
	ItemType.INTERNAL_AFFAIRS_COMPLAINT_ARCHIVE: INTERNAL_AFFAIRS_COMPLAINT_ARCHIVE,
	ItemType.BODY_CAM_FOOTAGE_DELETION_LOGS: BODY_CAM_FOOTAGE_DELETION_LOGS,
	ItemType.CONFIDENTIAL_INFORMANT_REGISTRY: CONFIDENTIAL_INFORMANT_REGISTRY,
	ItemType.EVIDENCE_LOCKER_ACCESS_CODES: EVIDENCE_LOCKER_ACCESS_CODES,
	ItemType.CORRUPTION_PAYOUT_LEDGER: CORRUPTION_PAYOUT_LEDGER,
	ItemType.SECRETARY_CACHE: SECRETARY_CACHE,
	ItemType.COP_CACHE: COP_CACHE,
	ItemType.DETECTIVE_CACHE: DETECTIVE_CACHE,
	ItemType.SERGEANT_CACHE: SERGEANT_CACHE,
	ItemType.CAPTAIN_CACHE: CAPTAIN_CACHE,
	ItemType.LEAKED_DEPOSITION_TRANSCRIPTS: LEAKED_DEPOSITION_TRANSCRIPTS,
	ItemType.FORGED_COURT_DOCUMENT_TEMPLATES: FORGED_COURT_DOCUMENT_TEMPLATES,
	ItemType.SEALED_CASE_FILES: SEALED_CASE_FILES,
	ItemType.OFFSHORE_ACCOUNT_RECORDS: OFFSHORE_ACCOUNT_RECORDS,
	ItemType.WITNESS_PROTECTION_ADDRESS: WITNESS_PROTECTION_ADDRESS,
	ItemType.LEGAL_ASSISTANT_CACHE: LEGAL_ASSISTANT_CACHE,
	ItemType.PARALEGAL_CACHE: PARALEGAL_CACHE,
	ItemType.ASSOCIATE_ATTORNEY_CACHE: ASSOCIATE_ATTORNEY_CACHE,
	ItemType.LAWYER_CACHE: LAWYER_CACHE,
	ItemType.PARTNER_CACHE: PARTNER_CACHE,
}
