"""
Generate synthetic insurance data CSVs for the Encova HOL.
Run this once to produce the data/ folder contents.

Usage: python3 generate_data.py
"""
import csv
import random
import os
from datetime import datetime, timedelta

random.seed(42)
DATA_DIR = os.path.dirname(os.path.abspath(__file__))

STATES = ['OH', 'IN', 'WV', 'VA', 'PA', 'KY', 'NC', 'TN', 'GA', 'MD', 'SC', 'IL']
CITIES = ['Columbus', 'Indianapolis', 'Charleston', 'Richmond', 'Pittsburgh',
          'Louisville', 'Charlotte', 'Nashville', 'Atlanta', 'Baltimore']
LINES_OF_BUSINESS = ['Commercial Property', 'General Liability', 'Workers Compensation',
                     'Commercial Auto', 'Business Owners Policy']
COVERAGE_TYPES = ['Property Damage', 'Bodily Injury', 'Medical Payments',
                  'Collision', 'Comprehensive', 'Umbrella']
LOSS_TYPES = ['Property Damage - Fire', 'Property Damage - Water', 'Property Damage - Wind/Hail',
              'Bodily Injury - Slip and Fall', 'Vehicle Collision', 'Theft/Burglary',
              'Workers Comp - Injury', 'Liability - Third Party']
CAUSES = ['Weather - Storm', 'Human Error', 'Equipment Failure', 'Negligence',
           'Criminal Activity', 'Natural Disaster', 'Workplace Accident']
INDUSTRIES = ['Manufacturing', 'Retail', 'Construction', 'Healthcare',
              'Transportation', 'Restaurant', 'Technology', 'Agriculture']
NOTE_TYPES = ['Initial Assessment', 'Investigation Update', 'Payment Processing',
              'Claimant Communication', 'Closure Summary']
SPECIALIZATIONS = ['Commercial Property', 'General Liability', 'Workers Compensation',
                   'Commercial Auto', 'Multi-Line']

LOSS_DESCRIPTIONS = [
    'Water damage from burst pipe in commercial building. Extensive damage to inventory and flooring.',
    'Vehicle rear-ended at intersection. Driver reports neck and back pain. Police report filed.',
    'Roof damage from severe thunderstorm with hail. Multiple shingles missing, interior water intrusion.',
    'Employee fell from ladder while performing maintenance. Fractured wrist, out of work 6 weeks.',
    'Fire started in kitchen area, spread to storage room. Significant structural damage. Fire dept responded.',
    'Break-in overnight. Security cameras show forced entry. Electronics and cash register stolen.',
    'Customer slipped on wet floor in retail store. Reported knee injury, seeking medical treatment.',
    'Delivery truck struck pedestrian in parking lot. Minor injuries reported. Witness statements collected.',
    'Wind damage to commercial signage and awning. Partial roof lift on north side of building.',
    'Forklift operator injured hand while loading equipment. Required emergency room visit and stitches.',
    'Flooding from heavy rainfall caused basement damage to stored inventory. No structural compromise.',
    'Multi-vehicle accident on highway. Insured driver not at fault. Dash cam footage available.',
    'Electrical fire in server room. Sprinkler system activated. Water and fire damage to equipment.',
    'Employee reported repetitive stress injury from assembly line work. Seeking workers comp benefits.',
    'Vandalism to storefront windows and exterior. Security footage shows two suspects.',
    'Tree fell on parked company vehicle during ice storm. Total loss likely.',
    'Contractor fell through unsecured opening on construction site. Broken leg, hospitalized.',
    'Grease fire in restaurant kitchen. Suppression system failed. Extensive kitchen rebuild needed.',
    'Truck jackknifed on icy highway. Cargo spilled. Environmental cleanup required.',
    'Slip and fall on icy parking lot. Customer fractured hip. Ambulance called to scene.',
]

NOTE_TEXTS = [
    'Contacted claimant via phone. They confirmed the timeline of events. No inconsistencies in their account. Proceeding with standard assessment.',
    'Site inspection completed. Damage is consistent with reported cause of loss. Photos uploaded to file. Recommend approval for repair estimate.',
    'Reviewed contractor estimate. Amount seems reasonable for scope of work. Approving payment minus deductible. Will notify policyholder.',
    'Claimant is frustrated with processing time. Escalated to supervisor. Need to expedite review and provide status update within 24 hours.',
    'Police report obtained. Details match claimant statement. No evidence of prior damage or fraud indicators. Proceeding with normal processing.',
    'Medical records received from treating physician. Injuries consistent with described accident. IME may not be necessary for this severity level.',
    'SUSPICIOUS: Timeline of events does not align with witness statements. Damage pattern inconsistent with reported cause. Referring to SIU for further investigation.',
    'Payment issued to claimant. Check number referenced in system. Closing file pending 30-day satisfaction period. No further action needed.',
    'Subrogation potential identified. Third party clearly at fault per police report. Opening recovery file and notifying subrogation unit.',
    'Weather data confirms severe storm in area on date of loss. NOAA records show wind gusts exceeding 70mph. Claim is weather-related, approved.',
    'Claimant attorney has sent letter of representation. All future communication must go through counsel. Updating file restrictions.',
    'Repair completed and final inspection passed. Work quality is satisfactory. Releasing final payment to contractor. File ready for closure.',
    'Claim denied per policy exclusion for pre-existing damage. Evidence shows damage predates policy effective date. Denial letter sent to insured.',
    'Multiple claims from same location within 6 months. Pattern suggests possible fraud. Flagging for SIU review before further processing.',
    'Workers comp claim validated. Employee was performing regular duties when injury occurred. Employer confirms no safety violations. Approving benefits.',
]


def rand_date(start_days_ago=365, end_days_ago=0):
    d = datetime.now() - timedelta(days=random.randint(end_days_ago, start_days_ago))
    return d.strftime('%Y-%m-%d')


def rand_ts(start_days_ago=365):
    d = datetime.now() - timedelta(days=random.randint(0, start_days_ago),
                                    hours=random.randint(0, 23),
                                    minutes=random.randint(0, 59))
    return d.strftime('%Y-%m-%d %H:%M:%S')


print("Generating policies.csv...")
with open(os.path.join(DATA_DIR, 'policies.csv'), 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['POLICY_ID', 'POLICY_NUMBER', 'POLICYHOLDER_NAME', 'LINE_OF_BUSINESS',
                'COVERAGE_TYPE', 'EFFECTIVE_DATE', 'EXPIRATION_DATE', 'PREMIUM_AMOUNT',
                'DEDUCTIBLE_AMOUNT', 'COVERAGE_LIMIT', 'STATE', 'AGENCY_CODE',
                'UNDERWRITER_ID', 'STATUS', 'CREATED_AT'])
    for i in range(10000):
        eff = datetime.now() - timedelta(days=random.randint(30, 730))
        exp = eff + timedelta(days=random.randint(30, 365))
        status = random.choices(['ACTIVE', 'CANCELLED', 'EXPIRED'], weights=[80, 10, 10])[0]
        w.writerow([
            f'POL-{i:07d}',
            f'ENC-2026-{i:06d}',
            f'Policyholder_{i}',
            random.choice(LINES_OF_BUSINESS),
            random.choice(COVERAGE_TYPES),
            eff.strftime('%Y-%m-%d'),
            exp.strftime('%Y-%m-%d'),
            round(random.uniform(500, 50000), 2),
            round(random.uniform(250, 10000), 2),
            round(random.uniform(50000, 5000000), 2),
            random.choice(STATES),
            f'AGN-{random.randint(1, 200):03d}',
            f'UW-{random.randint(1, 30):03d}',
            status,
            rand_ts(365),
        ])

print("Generating claimants.csv...")
with open(os.path.join(DATA_DIR, 'claimants.csv'), 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['CLAIMANT_ID', 'CLAIMANT_NAME', 'CLAIMANT_TYPE', 'BUSINESS_NAME',
                'INDUSTRY', 'CONTACT_EMAIL', 'CONTACT_PHONE', 'ADDRESS_STATE',
                'ADDRESS_CITY', 'DATE_OF_BIRTH', 'CREATED_AT'])
    for i in range(8000):
        ctype = random.choice(['Individual', 'Business', 'Third Party'])
        bname = f'Business_{i}' if ctype == 'Business' else ''
        w.writerow([
            f'CLM-{i:06d}',
            f'Claimant_{i}',
            ctype,
            bname,
            random.choice(INDUSTRIES),
            f'claimant_{i}@email.com',
            f'555-{random.randint(100,999):03d}-{random.randint(1000,9999):04d}',
            random.choice(STATES),
            random.choice(CITIES),
            (datetime.now() - timedelta(days=random.randint(7300, 25550))).strftime('%Y-%m-%d'),
            rand_ts(500),
        ])

print("Generating claims_raw.csv...")
with open(os.path.join(DATA_DIR, 'claims_raw.csv'), 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['CLAIM_ID', 'POLICY_ID', 'CLAIMANT_ID', 'CLAIM_NUMBER', 'DATE_OF_LOSS',
                'DATE_REPORTED', 'CLAIM_STATUS', 'LOSS_TYPE', 'LOSS_DESCRIPTION',
                'LOSS_LOCATION_STATE', 'LOSS_LOCATION_CITY', 'ESTIMATED_AMOUNT',
                'PAID_AMOUNT', 'RESERVED_AMOUNT', 'ADJUSTER_ID', 'FRAUD_INDICATOR',
                'SEVERITY', 'CAUSE_OF_LOSS', 'WEATHER_RELATED', 'LITIGATION_FLAG', 'CREATED_AT'])
    statuses = ['OPEN', 'UNDER_INVESTIGATION', 'APPROVED', 'PAID', 'CLOSED', 'DENIED']
    for i in range(10000):  # Reduced from 50K — 10K × 3 AI functions = 30K LLM calls (1/5 the cost)
        dol = datetime.now() - timedelta(days=random.randint(1, 365))
        dor = dol + timedelta(days=random.randint(0, 14))
        fraud = random.choices(['NONE', 'SUSPICIOUS', 'CONFIRMED'], weights=[89, 8, 3])[0]
        severity = random.choices(['LOW', 'MEDIUM', 'HIGH'], weights=[35, 50, 15])[0]
        w.writerow([
            f'CL-{i:07d}',
            f'POL-{random.randint(0,9999):07d}',
            f'CLM-{random.randint(0,7999):06d}',
            f'ENC-CLM-2026-{i:06d}',
            dol.strftime('%Y-%m-%d'),
            dor.strftime('%Y-%m-%d'),
            random.choice(statuses),
            random.choice(LOSS_TYPES),
            random.choice(LOSS_DESCRIPTIONS),
            random.choice(STATES),
            random.choice(CITIES),
            round(random.uniform(500, 500000), 2),
            round(random.uniform(0, 400000), 2),
            round(random.uniform(0, 200000), 2),
            f'ADJ-{random.randint(1,50):03d}',
            fraud,
            severity,
            random.choice(CAUSES),
            random.choice([True, True, False, False, False, False, False]),
            random.choice([True, False, False, False, False, False, False, False, False, False]),
            rand_ts(365),
        ])

print("Generating agents.csv...")
with open(os.path.join(DATA_DIR, 'agents.csv'), 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['AGENT_ID', 'AGENT_NAME', 'AGENCY_NAME', 'AGENCY_CODE', 'LICENSE_STATE',
                'SPECIALIZATION', 'YEARS_EXPERIENCE', 'TOTAL_POLICIES', 'PERFORMANCE_RATING',
                'CREATED_AT'])
    for i in range(200):
        w.writerow([
            f'AGT-{i:03d}',
            f'Agent_{i}',
            f'Agency_{random.randint(1,50)}',
            f'AGN-{i:03d}',
            random.choice(STATES[:6]),
            random.choice(SPECIALIZATIONS),
            random.randint(1, 35),
            random.randint(10, 500),
            round(random.uniform(2.0, 5.0), 1),
            rand_ts(1000),
        ])

print("Generating claim_notes.csv...")
with open(os.path.join(DATA_DIR, 'claim_notes.csv'), 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['NOTE_ID', 'CLAIM_ID', 'NOTE_DATE', 'NOTE_AUTHOR', 'NOTE_TYPE',
                'NOTE_TEXT', 'CREATED_AT'])
    for i in range(6000):  # ~0.6 notes per claim on average
        w.writerow([
            f'NOTE-{i:07d}',
            f'CL-{random.randint(0,9999):07d}',
            rand_ts(365),
            f'Adjuster_{random.randint(1,50)}',
            random.choice(NOTE_TYPES),
            random.choice(NOTE_TEXTS),
            rand_ts(365),
        ])

print("Done! Files generated in:", DATA_DIR)
